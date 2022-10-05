-module(push).
-import(lists,[nth/2]).
-import(topo,[createLine/1,createFull/1,create3D/1]).
-import(topo,[printCons/1,printCons3D/1,flatten/1]).
-export([start/1,nd/4,ndIsDone/1]).

nd(_,_, 3, Ayd) -> 
    Ayd ! done;
    
nd(S, W, C, Ayd) ->
    % io:format("~p : ~p~n",[self(),C]),
    receive
        {link, Pid} ->
            link(Pid),
            nd(S, W, C, Ayd);
        {msg, {S1, W1}} ->
            % timer:sleep(30),
            SNew = S+S1, WNew = W+W1,
            {links,Nbs} = process_info(self(), links),
            % io:format("~p ~p~n",[self(), Nbs]),
            if
                Nbs==[] ->
                    
                    Ayd ! done;
                true ->
                    K = rand:uniform(length(Nbs)),
                    % timer:sleep(10),
                    nth(K,Nbs) ! {msg,{SNew/2,WNew/2}},
                    if
                        SNew/WNew - S/W =< 0.0000000001 -> nd(SNew/2, WNew/2, C+1, Ayd);
                        true -> nd(SNew/2, WNew/2, 0, Ayd)
                    end
            end
    end.

ndIsDone(false) ->
    receive
        done ->
            done
    end,
    ndIsDone(false);
ndIsDone(true) ->
    receive
        done -> pushPid ! done
            
    end,
    ndIsDone(false).
    % ndIsDone(N-1,NodeList).

createNodes1D(Arr, 0, _, _,_) -> Arr;
createNodes1D(Arr, Len, Mod,[C],Ayd) ->
    createNodes1D([spawn(Mod,nd,[C,1,0,Ayd])|Arr], Len-1, Mod, [C+1],Ayd).

% createNodes2D(Arr, _, 0, _, _) -> Arr;
% createNodes2D(Arr, N, Len, Mod, Paras) ->
%     createNodes2D([createNodes1D([],N, Mod, Paras)| Arr],N, Len-1, Mod, Paras).

% createNodes3D(Arr, _, 0, _, _) -> Arr;
% createNodes3D(Arr, N, Len, Mod, Paras) ->
%     createNodes3D([createNodes2D([],N,N,Mod,Paras)|Arr],N, Len-1, Mod, Paras).

start(N) ->
    
    register(pushPid, self()),
    Ayd = spawn(push, ndIsDone,[true]),
    NodeList = createNodes1D([],N, push, [1], Ayd),
    % io:format("~p~n",[NodeList]),
    createLine(NodeList),
    io:format("~p~n",[statistics(wall_clock)]),
    FlatList = flatten(NodeList),
    io:format("~p~n",[FlatList]),
    nth(rand:uniform(length(FlatList)),FlatList) ! {msg, {0,0}},
    receive 
        done -> 
            % {_, Time1} = statistics(runtime),
            % {_, Time2} = statistics(wall_clock),
            io:format("~p~n",[statistics(wall_clock)]),
            % U1 = Time1,
            % U2 = Time2,
            % [X ! count || X <- FlatList],
            % io:format("Time elapsed : ~p ~n", [U2]),
            % timer:sleep(100)
            unregister(pushPid)
    end.
    % unregister(areYouDone),
