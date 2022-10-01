-module(push).
-import(lists,[nth/2]).
-import(topo,[createLine/1,createFull/1,create3D/1]).
-import(topo,[printCons/1,printCons3D/1,flatten/1]).
-export([start/1,nd/3,ndIsDone/0]).

nd(S,W, 3) -> 
    io:format("~p is done~n",[self()]),
    areYouDone ! done,
    nd(S,W,3);
    % receive
    %     count -> io:format("~p ~p~n", [self(),1])
    % end;
nd(S, W, C) ->
    io:format("~p : ~p~n",[self(),C]),
    receive
        {link, Pid} -> 
            link(Pid),
            nd(S, W, C);
        {msg, {S1, W1}} ->
            timer:sleep(30),
            SNew = S+S1, WNew = W+W1,
            {links,Nbs} = process_info(self(), links),
            io:format("~p ~p~n",[self(), Nbs]),
            if
                Nbs==[] -> areYouDone ! done;
                true ->
                    K = rand:uniform(length(Nbs)),
                    timer:sleep(10),
                    nth(K,Nbs) ! {msg,{SNew/2,WNew/2}},
                    if 
                        SNew/WNew - S/W =< 0.00001 -> nd(SNew/2, WNew/2, C+1);
                        true -> nd(SNew/2, WNew/2, 0)
                    end
            end;
        count ->
            io:format("~p ~p~n", [self(),S/W]),
            exit("Done")
    end.

% isProcessAlive(NodeList) ->
%     [io:format("~p~n",[is_process_alive(X)]) || X<-NodeList].
% ndIsDone(0,_)-> 
%     receive
%         done ->
%             io:format("O processes remain~n")
%     end;
% ndIsDone(1,NodeList)-> 
%     pushPid ! stop,
%     receive
%         done ->
%             % isProcessAlive(NodeList),
%             io:format("One nd is done~n")
%     end,
%     ndIsDone(0,NodeList);
% ndIsDone(-1,NodeList) -> ndIsDone(0,NodeList);
ndIsDone() ->
    receive
        done ->
            {_, Time1} = statistics(runtime),
            {_, Time2} = statistics(wall_clock),
            U1 = Time1,
            U2 = Time2,
            % [X ! count || X <- FlatList],
            io:format("Time elapsed : ~p (~p)~n", [U1,U2]),
            timer:sleep(100)
    end,
    ndIsDone().
    % ndIsDone(N-1,NodeList).

createNodes1D(Arr, 0, _, _) -> Arr;
createNodes1D(Arr, Len, Mod,[C]) ->
    createNodes1D([spawn(Mod,nd,[C,1,0])|Arr], Len-1, Mod, [C+1]).

% createNodes2D(Arr, _, 0, _, _) -> Arr;
% createNodes2D(Arr, N, Len, Mod, Paras) ->
%     createNodes2D([createNodes1D([],N, Mod, Paras)| Arr],N, Len-1, Mod, Paras).

% createNodes3D(Arr, _, 0, _, _) -> Arr;
% createNodes3D(Arr, N, Len, Mod, Paras) ->
%     createNodes3D([createNodes2D([],N,N,Mod,Paras)|Arr],N, Len-1, Mod, Paras).

start(N) ->
    register(pushPid, self()),
    NodeList = createNodes1D([],N, push, [1]),
    register(areYouDone, spawn(push, ndIsDone,[])),
    io:format("~p~n",[NodeList]),
    createLine(NodeList),
    timer:sleep(1),
    printCons(NodeList),
    % createLine(NodeList),
    
    % % createFull(NodeList),
    % timer:sleep(100),
    % % printCons(NodeList),
    statistics(runtime),
    statistics(wall_clock),
    FlatList = flatten(NodeList),
    io:format("~p~n",[FlatList]),
    nth(rand:uniform(length(FlatList)),FlatList) ! {msg, {0,0}},
    

    unregister(pushPid),
    unregister(areYouDone),
    done.
