-module(ga).
-import(lists,[nth/2]).
-export([start/1,nd/1,createLine/1,createFull/1,
    printCons/1,createNodes3D/3]).

nd(1) -> 
    startPid ! stop,
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
            % io:format("Links of ~p : ~p~n",[self(),Nbs]),
            % io:format("Length of Nbs:~p~n",[length(Nbs)]),
            K = rand:uniform(length(Nbs)),
            timer:sleep(100),
            nth(K,Nbs) ! {msg,Msg};
        count ->
            % startPid ! {self(), N}
            io:format("~p ~p~n", [self(),N]),
            exit("Done")
    end,
    nd(N-1).
createNodes1D(Arr, 0) -> Arr;
createNodes1D(Arr, Len) ->
    createNodes1D([spawn(ga,nd,[10])|Arr], Len-1).

createNodes2D(Arr, _, 0) -> Arr;
createNodes2D(Arr, N, Len) ->
    createNodes2D([createNodes1D([],N)| Arr],N, Len-1).

createNodes3D(Arr, _, 0) -> Arr;
createNodes3D(Arr, N, Len) ->
    createNodes3D([createNodes2D([],N,N)|Arr],N, Len-1).

createLine([N1, N2 | []]) -> N1 ! {link, N2};
createLine([N1, N2 | Rest]) ->
    timer:sleep(1),
    N2 ! {link,N1},
    createLine([N2|Rest]).

createFull(Arr) ->
    [X ! {link,Y} || Y <- Arr , X <- Arr],
    fullNetworkCreated.

create3D(Arr) ->
    [[createLine(X) || X <- Y] || Y <- Arr],
    timer:sleep(10),
    [[[nth(N,nth(Row,nth(Layer, Arr))) ! {link, nth(N,nth(Row+1,nth(Layer, Arr)))}
        || N<-lists:seq(1,length(Arr))]
        || Row<-lists:seq(1,length(Arr)-1)] 
        || Layer<-lists:seq(1,length(Arr))
    ].

printCons([]) -> donePrintCons;
printCons([H|T]) ->
    io:format("~p ~n",[process_info(H,links)]),
    printCons(T).
printCons3D(NodeList) ->
    [[printCons(X) || X <- Y] || Y <- NodeList].

start(N) ->
    register(startPid, self()),
    NodeList = createNodes3D([],N,N),
    io:format("~p~n",[NodeList]),
    create3D(NodeList),
    printCons3D(NodeList),
    % createLine(NodeList),
    
    % % createFull(NodeList),
    % timer:sleep(100),
    % % printCons(NodeList),
    % statistics(runtime),
    % statistics(wall_clock),
    % nth(rand:uniform(N),NodeList) ! {msg, hello},
    % receive
    %     stop ->
    %         {_, Time1} = statistics(runtime),
    %         {_, Time2} = statistics(wall_clock),
    %         U1 = Time1,
    %         U2 = Time2,
    %         [X ! count || X <- NodeList],
    %         io:format("Time elapsed : ~p (~p)~n", [U1,U2])
    % end,
    
    % unregister(startPid),
    done.