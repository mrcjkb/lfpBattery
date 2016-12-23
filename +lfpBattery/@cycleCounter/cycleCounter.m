classdef (Abstract) cycleCounter < handle
    %CYCLECOUNTER: Abstract class for counting cycles.
    %
    %   c = cycleCounter;                       creates a cycleCounter object for a battery with
    %                                           SoC_max = 1 and initializes with an SoC of 0
    %   c = cycleCounter(init_soc);             initializes with an SoC of init_soc
    %   c = cycleCounter(init_soc, soc_max);    specifies the maximum allowed SoC of the battery
    %
    %SoC values are recorded until a full cycle is completed (i. e. the
    %state of charge SoC reaches the maximum SoC SoC_max of the battery).
    %Each time this occurs, a specified cycle counting method is
    %used to count smaller cycles, which are output as a cycle-depth-of-cycle
    %histogram (cDoC) and the flag isnewC is set to true.
    %
    %The cycle-depth-of-cycle histogram can be used in aging models.
    %
    %cycleCounter Methods:
    %
    %   cycleCounter - cycleCounter constructor
    %   update       - Use this method to add a new SoC value to a cycleCounter
    %                   object c. If a new full cycle is reached, the count() method is
    %                   called.
    %   count        - (Abstract) Transforms the state-of-charge (SoC) profile into a
    %                   cycle-depth-of-discharge (cDoC) histogram using a specified cycle counting algorithm
    %   iMaxima      - Returns the indexes of the local maxima in the SoC
    %                  profile. To be called from within the count()
    %                  method.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, November 2016
    
    properties (SetAccess = 'protected')
        cDoC; % cycle - depth of cycle histogram
        isnewC = false; % true indicates that a new full cycle has started and that a new cDoC histogram has been calculated for the current cycle.
    end % public properties
    properties (GetAccess = 'protected', Hidden = true)
        socMax; % maximum allowed soc
    end
    properties (SetAccess = 'protected', GetAccess = 'protected', Hidden = true)
        currCycle; % current SoC profile between two socMax
        ct = int32(1); % counter for "intelligent indexing"
        soc0; % last soc
    end % hidden properties
    methods
        %% constructor
        function c = cycleCounter(init_soc, soc_max)
            % CYCLECOUNTER constructor:
            %
            %   c = cycleCounter;                       creates a cycleCounter object for a battery with
            %                                           SoC_max = 1 and initializes with an SoC of 0
            %   c = cycleCounter(init_soc);             initializes with an SoC of init_soc
            %   c = cycleCounter(init_soc, soc_max);    specifies the maximum allowed SoC of the battery
            %
            %SoC values are recorded until a full cycle is completed (i. e. the
            %state of charge SoC reaches the maximum SoC SoC_max of the battery).
            %Each time this occurs, a specified cycle counting method is
            %used to count smaller cycles, which are output as a cycle-depth-of-cycle
            %histogram (cDoC) and the flag isnewC is set to true.
            
            if nargin == 0
                init_soc = eps; % Zero reserved for recognition of initialized memory
                soc_max = 1;
            elseif nargin == 1
                soc_max = 1;
            end
            if soc_max > 1 || soc_max < 0
                error('soc_max must be between 0 and 1')
            elseif init_soc > soc_max
                error('init_soc must be smaller than soc_max')
            end
            init_soc(init_soc == 0) = eps;
            c.currCycle = [init_soc; nan]; % nan to make sure it is a column vector
            c.soc0 = init_soc;
            c.socMax = soc_max;
        end % constructor
        %% update method
        function c = update(c, soc)
            %UPDATE: Use this method to add a new SoC value to a
            %cycleCounter object c. If a new full cycle is reached, the count() method is
            %called.
            if soc ~= c.soc0 % ignore idle states
                if soc == c.socMax % full cycle reached
                    c.addSoC(soc);
                    c.isnewC = true; % set flag that new results have been calculated
                    c.count; % count cycles
                    % reset SoC
                    c.currCycle = c.currCycle.*0;
                    c.ct = int32(1);
                    c.currCycle(1) = soc;
                else
                    c.isnewC = false;
                    c.addSoC(soc);
                    c.isnewC = false;
                end
            else
                c.isnewC = false;
            end
            c.soc0 = soc;
        end % update
        
    end % public methods
    
    methods (Abstract)
        % COUNT: Transforms the state-of-charge (SoC) profile into a
        % cycle-depth-of-discharge (cDoC) histogram using a specified cycle counting algorithm
        c = count(c);
    end
    
    %% protected methods
    methods (Access = 'protected')
        function c = addSoC(c, soc)
            %ADDSOC: increments indexing counter and adds soc to currCycle
            c.ct = c.ct + 1;
            c.currCycle(c.ct) = soc;
        end
        %% maximum finder
        function imax = iMaxima(c)
            %IMAXIMA: finds the indices of the local maxima in the
            %SoC-profile stored within a cycleCounter c.
            %Syntax: imax = c.iMaxima;
            %
            %Output:
            %   - imax: Indexes of the local maxima of SoC
            %
            %Relevant code used from extrema
            %https://de.mathworks.com/matlabcentral/fileexchange/12275-extrema-m--extrema2-m
            %
            %NOTE: NaNs are not filtered in this function.
            
            Nt = numel(c.currCycle(1:c.ct));
            a = int32((1:Nt)');
            b = (diff(c.currCycle(1:c.ct)) > 0);     %1  =>  positive slope (begin of minima)
            %0  =>  negative slope (begin of maxima)
            xb  = diff(b);          %-1 =>  indices of maxima
            %+1 =>  indices of minima
            imax = a(find(xb == -1) + 1); % indices of maxima
            imin = a(find(xb == 1) + 1); % indices of minima
            nmaxi = numel(imax);
            nmini = numel(imin);
            % Maximum or minumim at the ends? (for initialization)
            if (nmaxi == 0)
                imax = zeros(0, 0, 'int32');
            else
                if imax(1) < imin(1)
                    imin(2:nmini+1) = imin;
                    imin(1) = 1;
                else
                    imax(2:nmaxi+1) = imax;
                    imax(1) = 1;
                end
                if imax(end) <= imin(end)
                    imax(end+1) = Nt;
                end
            end
        end % iMaxima
    end % protected methods
end % of classdef

