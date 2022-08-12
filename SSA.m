function trajectory = SSA(tmesh, par, prop, stoch, init, thcstart, thcend)
    %tmesh - time mesh on which solution should be returned
    %per - parameters of the pathway
    %prop - definition of propensity functions
    %stoch - stochiometric matrix
    %init - initial condition for the pathway
    
    updateRateHz = 10;
    b = ProgressBar([], 'Title', 'Simulating', 'UpdateRate', updateRateHz);
    t = 0;                                           %current time
    state = init(:);                                 %variable with current system state
    trajectory = zeros(length(init), length(tmesh)); %preparing output trajectory
    trajectory(:, 1) = init(:);                      %setting initial value as the first element in trajectory
    cindx = 2;                                       %current trajectory index
    N = length(tmesh);                               %number of time points
    
    while t < tmesh(end)
        Q = feval(prop, state, par);        %calculating propensities of the reactions
        for i=1:size(Q)
            if Q(i) < 0
                Q(i) = +0.0; % since propensity functions include square items, when the system lacks something
                % some propensity functions may be positive and bigger and bigger as the iteration goes on
            end
        end
        qq = Q(Q > 0);
        Qs = sum(Q);                        %total propensity
        dt = -log(rand())/Qs;               %generating time to the next reaction
        R = sum(rand >= cumsum([0, Q])/Qs); %selecting reaction
        state = state + stoch(:, R);        %updating state
        if ~isempty(find(state < 0, 1))     %in case there are substrates of negative amount
            state = state - stoch(:, R);
            state = state + stoch(:, randperm(numel(qq), 1));
        end
        t = t + dt;                         %updating time
    
        %writing the output
        while cindx <= N && t > tmesh(cindx)
            trajectory(:, cindx) = state;
            cindx = cindx+1;
        end
        b(1, [], []);
        if t >= thcstart && t <= thcend %THC takein time interval
            par.c29 = 0.5; %parameter modified
        end
        if t > thcend
            par.c29 = 150;
        end
    end
%     b.release();
end