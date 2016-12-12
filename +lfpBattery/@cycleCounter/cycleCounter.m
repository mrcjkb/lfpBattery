classdef cycleCounter
    %CYCLECOUNTER: Interface for counting cycles according to J. Dambrowski,
    %S. Pichlmaier, A. Jossen - "Mathematical methods for classification of
    %state-of-charge time series for cycle lifetime prediction".
    %
    %   c = cycleCounter;                       creates a cycleCounter object for a battery with
    %                                           SoC_max = 1 and initializes with an SoC of 0
    %   c = cycleCounter(init_soc);             initializes with an SoC of init_soc
    %   c = cycleCounter(init_soc, soc_max);    specifies the maximum allowed SoC of the battery
    %
    %SoC values are recorded until a full cycle is completed (i. e. the
    %state of charge SoC reaches the maximum SoC SoC_max of the battery).
    %Each time this occurs, the aforementioned cycle counting method is
    %used to count smaller cycles, which are output as a cycle-depth-of-cycle
    %histogram (cDoC) and the flag isnewC is set to true.
    %
    %The cycle-depth-of-cycle histogram can be used in aging models.

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
            % CYCLECOUNTER constructor
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
            %cycleCounter object c.
            if soc ~= c.soc0 % ignore idle states
                if soc == c.socMax % full cycle reached
                    c = c.addSoC(soc);
                    c.isnewC = true; % set flag that new results have been calculated
                    c = c.dambrowskiCount; % count cycles
                    % reset SoC
                    c.currCycle = c.currCycle.*0;
                    c.ct = int32(1);
                    c.currCycle(1) = soc;
                else
                    c.isnewC = false;
                    c = c.addSoC(soc);
                    c.isnewC = false;
                end
            else
                c.isnewC = false;
            end
            c.soc0 = soc;
        end % update
        %% cycle counter
        function c = dambrowskiCount(c)
            %DAMBROWSKICOUNT: Transforms the state-of-charge (SoC) profile into a
            %cycle-depth-of-discharge (cDoC) histogram using the method described
            %in J. Dambrowski, S. Pichlmaier, A. Jossen - "Mathematical methods for
            %classification of state-of-charge time series for cycle lifetime
            %prediction".
            %
            %Syntax:    c.dambrowskiCount;
            
            SoC = c.currCycle(1:c.ct);
            %% eliminate extensive peaks [with diff(SoC) == 0]
            SoC([false; diff(SoC) == 0]) = [];
            SoC(SoC == 0) = eps; % zeros are reserved for possible expanding matrices
            %% find indexex of maxima
            imax = c.iMaxima;
            if ~isempty(imax)
                nmax = int32(numel(imax));
                t = int32((1:numel(SoC))'); % virtual time stamp
                % imax: Indexes of the local Maxima of SoC profile
                %% Determination of same SoC before and after maxima
                ipe = zeros(size(imax), 'int32'); % i_prior_equality - indexes of values of prior equality
                ise = ipe; % i_subsequent_equality - indexes of values of subsequent equality
                maxRows = numel(imax);
                kpe = ones(1,1,'int32'); % prior equality counter
                kse = ones(1,1,'int32'); % subsequent equality counter
                % sums of the virtual time stamps of minima in pre-cycles
                % Repeated values of Pmsums/Smsums are shared local minima.
                Pmsums = zeros(maxRows, 1, 'int32'); % P: prior equality
                Smsums = Pmsums; % S: subsequent equality
                % sizes of the intervals
                Pintsizes = zeros(maxRows, 1, 'int32');
                Sintsizes = Pintsizes;
                % extrema of pre-cycles
                Pmax = zeros(maxRows, 1);
                Pmin = Pmax;
                Smax = Pmax;
                Smin = Pmax;
                for i = int32(1):int32(numel(imax))
                    % index of last maximum equal to or larger than current maximum
                    im = imax(1:max(1,i-1));
                    st = find(SoC(im) >= SoC(imax(i))); % starting index
                    if isempty(st) % start from position 1 if no prior equality point found
                        st = 1;
                    end
                    st = im(st(end)); % last index of prior equality
                    tmp1 = SoC(st:imax(i)-1) - SoC(imax(i)); % abs(min(tmp1)) = Positions, at which SoC before SoC(imax(i)) == SoC(imax(i))
                    tmp2 = tmp1 <= 0;
                    % Condition: SoC(t) <= SoC(t1) for all t1 <= t <= t2
                    if  any(tmp2) % Is there a "prior-equality-point"?
                        ipe(i) = st + int32(tmp2(1));
                        Pintsizes(i) = abs(imax(i)-ipe(i));
                        pcy = SoC(ipe(i):imax(i)); % pre-cycle prior equality
                        t_pcy = t(ipe(i):imax(i)); % equivalent virtual time stamp
                        Pmsums(i) = sum(t_pcy(pcy == min(pcy))); % time of minimum
                        Pmax(i) = SoC(imax(i));
                        Pmin(i) = min(pcy);
                        kpe = kpe + 1; % increment counter
                    end
                    % index of next maximum equal to or larger than current maximum
                    im = imax(min(nmax,i+1):end);
                    en = im(find(SoC(im) >= SoC(imax(i)), 1));
                    warning('off','all')
                    tmp1 = SoC(imax(i)) - SoC(imax(i)+1:en);
                    tmp2 = find(tmp1 >= 0);
                    warning('on','all')
                    % Condition: SoC(t) <= SoC(t1) for all t1 <= t <= t2
                    if  ~isempty(tmp2)
                        ise(i) = imax(i) + int32(tmp2(max(1, numel(tmp2)-1)));
                        Sintsizes(i) = abs(ise(i) - imax(i));
                        pcy = SoC(imax(i):ise(i)); % pre-cycle subsequent equality
                        t_pcy = t(imax(i):ise(i)); % equivalent virtual time stamp
                        Smsums(i) = sum(t_pcy(pcy == min(pcy))); % time of minimum
                        Smax(i) = SoC(imax(i));
                        Smin(i) = min(pcy);
                        kse = kse + 1;
                    end
                end
                % shorten intermediate results
                Pintsizes = Pintsizes(1:kpe-1);
                Pmsums = Pmsums(1:kpe-1);
                Pmax = Pmax(1:kpe-1);
                Pmin = Pmin(1:kpe-1);
                Sintsizes = Sintsizes(1:kse-1);
                Smsums = Smsums(1:kse-1);
                Smax = Smax(1:kse-1);
                Smin = Smin(1:kse-1);
                %% Eliminate first non-cycles (using duplicates in the virtual time stamp)
                % filter1 = 1 if there is no greater interval [t3, t4] that shares
                % the local minimum with the interval [t1, t2]
                filter1 = false(size(Pmsums));
                % filter2 = 1 if there is no greater interval [t3, t4] that shares
                % the local minimum with the interval [t1, t2]
                filter2 = false(size(Smsums));
                i1 = min(kpe-1, kse-1); % kpe-1 == numel(Pmsums); kse-1 == numel(Smsums)
                i2 = max(kpe-1, kse-1);
                for i = int32(1):i1
                    idx = ismember(Pmsums, Pmsums(i));
                    if Pintsizes(i) == max(Pintsizes(idx))
                        filter1(i) = true;
                    end
                    idx = ismember(Smsums, Smsums(i));
                    if Sintsizes(i) == max(Sintsizes(idx))
                        filter2(i) = true;
                    end
                end
                if kpe-1 > kse-1
                    for i = i1+1:i2
                        idx = ismember(Pmsums, Pmsums(i));
                        if Pintsizes(i) == max(Pintsizes(idx))
                            filter1(i) = true;
                        end
                    end
                elseif kpe-1 < kse-1
                    for i = i1+1:i2
                        idx = ismember(Smsums,Smsums(i));
                        if Sintsizes(i) == max(Sintsizes(idx))
                            filter2(i) = true;
                        end
                    end
                end
                Pmax = Pmax(filter1);
                Pmin = Pmin(filter1);
                Smax = Smax(filter2);
                Smin = Smin(filter2);
                %% Define cycles - check P & S for cross-sections with the same local minima
                allmSums = [Pmsums(filter1); Smsums(filter2)];
                allintsizes = [Pintsizes(filter1); Sintsizes(filter2)];
                allmax = [Pmax; Smax]; allmin = [Pmin; Smin];
                filter3 = false(size(allmSums));
                for i = int32(1):int32(numel(allmSums))
                    idx = ismember(allmSums, allmSums(i));
                    if allintsizes(i) == max(allintsizes(idx))
                        filter3(i) = true;
                        allintsizes(i) = allintsizes(i) + 1; % to exclude same size PE & SE
                    end
                end
                CycMax = allmax(filter3); %Maxima of the full cycles
                CycMin = allmin(filter3); %Minima of the full cycles
                cdoc = CycMax - CycMin; %cycle-depth of cycle histogram
                c.cDoC = cdoc(cdoc > 0);
            else % no cycles found (possible at initialization)
                c.isnewC = false;
            end
        end % dambrowskiCount
    end % public methods
    
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
            %SoC-profile
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

