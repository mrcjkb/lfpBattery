classdef rainflowCounter < lfpBattery.cycleCounter
    %RAINFLOWCOUNTER: Example of a cycle counter class that uses the rain flow counting algorithm.
    %This class requires Adam Nieslony's rainflow
    %MEX function, available for free on FileExchange:
    %http://mathworks.com/matlabcentral/fileexchange/3026-rainflow-counting-algorithm
    %
    %   c = RAINFLOWCOUNTER;                       creates a dambrowskiCounter object for a battery with
    %                                              SoC_max = 1 and initializes with an SoC of 0
    %   c = RAINFLOWCOUNTER(init_soc);             initializes with an SoC of init_soc
    %   c = RAINFLOWCOUNTER(init_soc, soc_max);    specifies the maximum allowed SoC of the battery
    %
    %SoC values are recorded until a full cycle is completed (i. e. the
    %state of charge SoC reaches the maximum SoC SoC_max of the battery).
    %Each time this occurs, the aforementioned cycle counting method is
    %used to count smaller cycles, which are output as a cycle-depth-of-cycle
    %histogram (cDoC).
    %
    %The cycle-depth-of-cycle histogram can be used in aging models.
    %
    %RAINFLOWCOUNTER Methods:
    %
    %   rainflowCounter   - rainflowCounter constructor
    %   update            - Use this method to add a new SoC value to a cycleCounter
    %                       object c. If a new full cycle is reached, the count() method is
    %                       called.
    %   count             - Transforms the state-of-charge (SoC) profile
    %                       into a cycle-depth-of-discharge (cDoC) histogram using the dambrowski et al. cycle counting algorithm
    %   lUpdate           - Add this method to a battery model using it's addlistener method.
    %
    %The RAINFLOWCOUNTER object will notify event listeners (e. g. aging models) about a new
    %full cycle occuring. To define an event listener Obj for a
    %RAINFLOWCOUNTER c, pass the c as follows, using Obj's addlistener
    %method:
    %
    %addlistener(c, 'NewCycle', @Obj.methodName)
    %
    %SEE ALSO: lfpBattery.eoAgeModel lfpBattery.dambrowskiCounter
    %lfpBattery.batteryAgeModel lfpBattery.cycleCounter
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         February 2017
    
    methods
        function c = rainflowCounter(varargin)
            %RAINFLOWCOUNTER: Example of a cycle counter class that uses the rain flow counting algorithm.
            %This class requires Adam Nieslony's rainflow
            %MEX function, available for free on FileExchange:
            %http://mathworks.com/matlabcentral/fileexchange/3026-rainflow-counting-algorithm
            %
            %   c = RAINFLOWCOUNTER;                       creates a dambrowskiCounter object for a battery with
            %                                              SoC_max = 1 and initializes with an SoC of 0
            %   c = RAINFLOWCOUNTER(init_soc);             initializes with an SoC of init_soc
            %   c = RAINFLOWCOUNTER(init_soc, soc_max);    specifies the maximum allowed SoC of the battery
            %
            %SoC values are recorded until a full cycle is completed (i. e. the
            %state of charge SoC reaches the maximum SoC SoC_max of the battery).
            %Each time this occurs, the aforementioned cycle counting method is
            %used to count smaller cycles, which are output as a cycle-depth-of-cycle
            %histogram (cDoC).
            %
            %The cycle-depth-of-cycle histogram can be used in aging models.
            [~, name, ext] = fileparts(which('rainflow'));
            if ~strcmp([name, ext], 'rainflow.mexw64')
                error('This class requires Adam Nieslony''s rainflow MEX function: http://mathworks.com/matlabcentral/fileexchange/3026-rainflow-counting-algorithm')
            end
            c = c@lfpBattery.cycleCounter(varargin{:});
        end % constructor
        function count(c)
            %COUNT: Transforms the state-of-charge (SoC) profile into a
            %cycle-depth-of-discharge (cDoC) histogram using the method described
            %in J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for
            %classification of state-of-charge time series for cycle lifetime
            %prediction".
            %
            %Syntax:    c.count;
            SoC = c.currCycle(1:c.ct);
            ext = sig2ext(SoC);
            rf = rainflow(ext); % amplitude = rf(1,:)
            half = rf(3,:) == 0.5; % indices of half cycles
            full = rf(1, ~half)' * 2; % full cycles (DoC = 2 * amplitude)
            half = rf(1, half)';
            cdoc = [full; half(1:2:end) + half(2:2:end)];
            c.cDoC = cdoc(cdoc > 0);
        end % count
    end
    
end

