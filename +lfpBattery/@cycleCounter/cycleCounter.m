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
    %histogram (cDoC).
    %
    %The cycle-depth-of-cycle histogram can be used in aging models.
    %
    %cycleCounter Methods:
    %
    %   cycleCounter - cycleCounter constructor
    %   update       - Use this method to add a new SoC value to a cycleCounter
    %                   object c. If a new full cycle is reached, the count() method is
    %                   called.
    %   lUpdate      - Called if cycleCounter is added to a model Obj as an event listener.
    %                  Calls the update method when Obj's SoC is updated.
    %   count        - (Abstract) Transforms the state-of-charge (SoC) profile into a
    %                   cycle-depth-of-discharge (cDoC) histogram using a specified cycle counting algorithm
    %   iMaxima      - Returns the indexes of the local maxima in the SoC
    %                  profile. To be called from within the count()
    %                  method.
    %
    %The CYCLECOUNTER object will notify event listeners (e. g. aging models) about a new
    %full cycle occuring. To define an event listener Obj for a
    %CYCLECOUNTER c, pass the c as follows, using Obj's addlistener
    %method:
    %
    %addlistener(c, 'NewCycle', @Obj.methodName)
    %
    %SEE ALSO: lfpBattery.eoAgeModel lfpBattery.dambrowskiCounter
    %lfpBattery.batteryAgeModel
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         November 2016
    
    properties (SetAccess = 'protected', Hidden)
        cDoC@double vector; % cycle - depth of cycle histogram
    end % public properties
    properties (GetAccess = 'protected', Hidden = true)
        socMax@double scalar; % maximum allowed soc
    end
    properties (Hidden, Access = 'protected')
        currCycle@double vector; % current SoC profile between two socMax
        ct@uint32 scalar = 1; % counter for "intelligent indexing"
        soc0@double scalar; % last soc
    end
    events
        NewCycle; % Notifies listeners that a new full cycle has started and that a new cDoC histogram has been calculated for the current cycle.
    end
    methods
        %% constructor
        function c = cycleCounter(init_soc, soc_max)
            %CYCLECOUNTER constructor:
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
            %histogram (cDoC).
            %
            %The CYCLECOUNTER object will notify event listeners (e. g. aging models) about a new
            %full cycle occuring. To define an event listener Obj for a
            %CYCLECOUNTER c, pass the c as follows, using Obj's addlistener
            %method:
            %
            %addlistener(c, 'NewCycle', @Obj.methodName)
            
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
        %%
        function lUpdate(c, ~, event)
            %LUPDATE: Add this method to a battery model b using it's
            %addlistener method.
            c.update(event.AffectedObject.soc);
        end
        function update(c, soc)
            %UPDATE: Use this method to add a new SoC value to a
            %cycleCounter object c. If a new full cycle is reached, the count() method is
            %called.
            if soc ~= c.soc0 % ignore idle states
                if soc >= c.socMax % full cycle reached
                    % In case of tolerances, set start and end values equal
                    c.addSoC(c.socMax);
                    % Make sure counting is correct
                    c.count; % count cycles
                    % reset SoC
                    c.currCycle = c.currCycle * 0;
                    c.ct = 1;
                    c.currCycle(1) = c.socMax;
                    if ~isempty(c.cDoC) % make sure algorithm didn't count the same cycles twice
                        notify(c, 'NewCycle'); % notify listeners about new full cycle being reached
                        c.cDoC = [];
                    end
                else
                    c.addSoC(soc);
                end
            end
            c.soc0 = soc;
        end % update
        
    end % public methods
    
    methods (Abstract)
        % COUNT: Transforms the state-of-charge (SoC) profile into a
        % cycle-depth-of-discharge (cDoC) histogram using a specified cycle counting algorithm
        count(c);
    end
    
    %% protected methods
    methods (Access = 'protected')
        function addSoC(c, soc)
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
            
            Nt = int32(numel(c.currCycle(1:c.ct)));
            a = (1:Nt)';
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
            % Only return unique values (faster than built-in unique
            % function)
            % NOTE: Revert to using unique() if this causes issues
            a = sort([1; imax(:); Nt]);
            imax = a([true; diff(a) ~= 0]);
%             imax = unique([1; imax(:); Nt]); % Old version
        end % iMaxima
    end % protected methods
end % of classdef

