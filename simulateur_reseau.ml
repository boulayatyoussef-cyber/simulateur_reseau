(* --- TYPES DU JEU --- *)
type packet = { src: string; dst: string; content: string; birth_tick: int }
type link = { node1: string; node2: string; latency: int; reliability: int; mutable active: bool }
type node = { name: string; mutable queue: (packet * int) list }
type network = { 
  nodes_list: node list; 
  nodes_map: (string, node) Hashtbl.t; 
  links: link list; 
  routes: (string, (string, string) Hashtbl.t) Hashtbl.t 
}
type game_state = { 
  mutable budget: int; 
  mutable score: int; 
  mutable delivered: int; 
  mutable lost: int 
}

(* --- COULEURS TERMINAL --- *)
let red s = "\027[31m" ^ s ^ "\027[0m"
let green s = "\027[32m" ^ s ^ "\027[0m"
let yellow s = "\027[33m" ^ s ^ "\027[0m"
let blue s = "\027[34m" ^ s ^ "\027[0m"

(* --- LOGIQUE DE ROUTAGE (TON EMPREINTE) --- *)
let neighbors net name =
  List.fold_left (fun acc l ->
    if l.active then
      if l.node1 = name then (l.node2, l.latency) :: acc
      else if l.node2 = name then (l.node1, l.latency) :: acc
      else acc
    else acc
  ) [] net.links

let dijkstra net start =
  let dist = Hashtbl.create 10 in
  let prev = Hashtbl.create 10 in
  let q = ref [] in
  List.iter (fun n -> Hashtbl.add dist n.name max_int; q := n.name :: !q) net.nodes_list;
  Hashtbl.replace dist start 0;
  while !q <> [] do
    let u = List.fold_left (fun best n -> 
      if List.mem n !q && (best = "" || Hashtbl.find dist n < Hashtbl.find dist best) then n else best) "" !q in
    if u = "" || Hashtbl.find dist u = max_int then q := []
    else (
      q := List.filter ((<>) u) !q;
      List.iter (fun (v, l) ->
        let alt = Hashtbl.find dist u + l in
        if alt < Hashtbl.find dist v then (Hashtbl.replace dist v alt; Hashtbl.replace prev v u)
      ) (neighbors net u)
    )
  done; (dist, prev)

let update_routes net =
  Hashtbl.clear net.routes;
  List.iter (fun n ->
    let _, prev = dijkstra net n.name in
    let table = Hashtbl.create 10 in
    List.iter (fun target ->
      try
        let rec find_next curr = 
          let p = Hashtbl.find prev curr in if p = n.name then curr else find_next p in
        if target.name <> n.name then Hashtbl.add table target.name (find_next target.name)
      with Not_found -> ()
    ) net.nodes_list;
    Hashtbl.add net.routes n.name table
  ) net.nodes_list

(* --- MOTEUR DE JEU --- *)
let send_packet net pkt st tick =
  if pkt.src = pkt.dst then (
    st.delivered <- st.delivered + 1;
    st.score <- st.score + 100;
    st.budget <- st.budget + 50;
    Printf.printf "  %s Paquet arrivé à %s ! (+100 pts)\n" (green "✔") pkt.dst
  ) else (
    st.budget <- st.budget - 5; (* Coût de transmission *)
    try
      let next_hop = Hashtbl.find (Hashtbl.find net.routes pkt.src) pkt.dst in
      let l = List.find (fun l -> (l.node1=pkt.src && l.node2=next_hop) || (l.node1=next_hop && l.node2=pkt.src)) net.links in
      if Random.int 100 < l.reliability then (
        let n_next = Hashtbl.find net.nodes_map next_hop in
        n_next.queue <- ({pkt with src = next_hop}, l.latency) :: n_next.queue;
        Printf.printf "  %s %s -> %s\n" (blue "✈") pkt.src next_hop
      ) else (
        Printf.printf "  %s Panne sur le lien %s-%s !\n" (red "✘") pkt.src next_hop;
        st.lost <- st.lost + 1
      )
    with _ -> (Printf.printf "  %s Pas de route vers %s !\n" (red "⚠") pkt.dst; st.lost <- st.lost + 1)
  )

let tick net st i =
  Printf.printf "\n%s --- TOUR %d (Budget: %d | Score: %d) ---\n" (yellow "==>") i st.budget st.score;
  (* Événement aléatoire : un lien tombe ou revient *)
  let random_link = List.nth net.links (Random.int (List.length net.links)) in
  if Random.int 100 < 10 then (
    random_link.active <- not random_link.active;
    if not random_link.active then Printf.printf "  %s Un câble a été coupé entre %s et %s !\n" (red "⚡") random_link.node1 random_link.node2;
    update_routes net
  );
  List.iter (fun n ->
    let q = n.queue in n.queue <- [];
    List.iter (fun (pkt, t) -> if t <= 1 then send_packet net pkt st i else n.queue <- (pkt, t-1) :: n.queue) q
  ) net.nodes_list

(* --- LANCEMENT --- *)
let () =
  Random.self_init ();
  let nodes = List.map (fun name -> {name; queue=[]}) ["Paris"; "Lyon"; "Marseille"; "Lille"] in
  let nodes_map = Hashtbl.create 4 in List.iter (fun n -> Hashtbl.add nodes_map n.name n) nodes;
  let links = [
    {node1="Paris"; node2="Lille"; latency=1; reliability=95; active=true};
    {node1="Paris"; node2="Lyon"; latency=2; reliability=90; active=true};
    {node1="Lyon"; node2="Marseille"; latency=2; reliability=85; active=true};
    {node1="Lille"; node2="Marseille"; latency=5; reliability=70; active=true}
  ] in
  let net = { nodes_list=nodes; nodes_map; links; routes=Hashtbl.create 4 } in
  let st = { budget=200; score=0; delivered=0; lost=0 } in
  update_routes net;
  
  (* Injection de paquets de départ *)
  (Hashtbl.find nodes_map "Paris").queue <- [({src="Paris"; dst="Marseille"; content="Secret"; birth_tick=0}, 0)];
  
  for i = 1 to 15 do
    if st.budget > 0 then (tick net st i; Unix.sleepf 0.5)
  done;
  Printf.printf "\n%s\n  SCORE FINAL : %d | LIVRÉS : %d | PERDUS : %d\n" (yellow "GAME OVER") st.score st.delivered st.lost
