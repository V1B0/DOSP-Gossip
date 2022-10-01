-module(gossip).
-import(lists,[nth/2]).
-import(topo,[createNodes1D/2,createNodes2D/3,createNodes3D/3,createLine/1,createFull/1,create3D/1]).
-import(topo,[printCons/1,printCons3D/1,flatten/1]).
-export([start/1,nd/1]).

nd(1) -> 
    gossipPid ! stop,
    receive
        count -> io:format("~p ~p~n", [self(),1])
    end;
nd(N) ->
    receive
        {link, Pid} -> 
            link(Pid),
            nd(N);
        {msg, Msg} ->
            {links,Nbs} = process_info(self(), links),
            K = rand:uniform(length(Nbs)),
            timer:sleep(10),
            nth(K,Nbs) ! {msg,Msg};
        count ->
            io:format("~p ~p~n", [self(),N]),
            exit("Done")
    end,
    nd(N-1).


start(N) ->
    register(gossipPid, self()),
    NodeList = createNodes3D([],N,N),
    io:format("~p~n",[NodeList]),
    create3D(NodeList),
    timer:sleep(1),
    printCons3D(NodeList),
    % createLine(NodeList),
    
    % % createFull(NodeList),
    % timer:sleep(100),
    % % printCons(NodeList),
    statistics(runtime),
    statistics(wall_clock),
    FlatList = flatten(NodeList),
    io:format("~p~n",[FlatList]),
    nth(rand:uniform(length(FlatList)),FlatList) ! {msg, hello},
    receive
        stop ->
            {_, Time1} = statistics(runtime),
            {_, Time2} = statistics(wall_clock),
            U1 = Time1,
            U2 = Time2,
            [X ! count || X <- FlatList],
            io:format("Time elapsed : ~p (~p)~n", [U1,U2])
    end,
    
    unregister(startPid),
    done.