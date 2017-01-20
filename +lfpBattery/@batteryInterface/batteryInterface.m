classdef (Abstract) batteryInterface < lfpBattery.composite
    %BATTERYINTERFACE: Abstract class / interface for creating battery
    %models. This is the common interface for batteryPacks, batteryCells,
    %seriesElements and parallelElements,...
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    properties
        % Maximum number of iterations.
        % The methods powerRequest() and powerIterator() iterate through
        % currents in order to find the current / voltage combination
        % required for a given power. Also, the SoC and current limitations
        % are handled using similar iterations. Set the maximum number of
        % iterations with the maxIterations property.
        % Reducing this number can decrease the simulation time, but can
        % also reduce the accuracy.
        maxIterations = uint32(1e3); 
        % Tolerance for the power iteration in W.
        % Increasing this number can decrease the simulation time, but can
        % also reduce the accuracy of the power requests.
        pTol = 1e-6; 
        % Tolerance for SoC limitation iteration.
        % Increasing this number can decrease the simulation time, but can
        % also reduce the accuracy of the SoC limitation.
        sTol = 1e-6;
        % Tolerance for current limitation iteration in A.
        % Increasing this number can decrease the simulation time, but can
        % also reduce the accuracy of the current limitation.
        iTol = 1e-6;
    end
    properties (SetAccess = 'immutable')
        eta_bc;
        % Efficiency when discharging [0,..,1].
        % Note: Set this property to 1 if only a total efficiency is given.
        eta_bd;
    end
    properties (Dependent, SetAccess = 'immutable')
        % Self discharge rate in 1/month [0,..,1] (default: 0)
        % By default, the self-discharge of the batteries is neglected.
        psd;
    end
    properties (Abstract, Dependent, SetAccess = 'immutable')
        Zi; % Internal impedance in Ohm
    end
    properties (Dependent, SetAccess = 'protected')
        SoH; % State of health [0,..,1]
    end
    properties (Abstract, Dependent, SetAccess = 'protected')
        % Discharge capacity in Ah (Cd = 0 if SoC = 1).
        % The discharge capacity is given by the nominal capacity Cn and
        % the current capacity C at SoC.
        % Cd = Cn - C
        Cd;
    end
    properties (Abstract, Dependent)
        V; % Resting voltage / V
    end
    properties (Dependent)
        % Max SoC (default: 1)
        % In some cases it may make sense to limit the SoC in order to
        % reduce aging effects.
        socMax;
        % Min SoC (default: 0.2)
        % In some cases it may make sense to limit the SoC in order to
        % reduce aging effects.
        % Note: If a current that was not fitted is used, the accuracy
        % of the voltage interpolation is drastically reduced at SoCs 
        % below 0.1 or 0.2, depending on the current.
        socMin;
        % State of charge [0,..,1].
        % In this model, the SoC is fraction between the current capacity
        % and the nominal capacity. SoC = C ./ Cn. Capacity loss due to
        % aging is not included in the SoC calculation.
        SoC;
        % Useable capacity in Ah.
        % This property takes into account aging effects (if an aging model
        % is used) and the SoC limitation.
        Cbu;
    end
    properties (SetAccess = 'protected')
        Imax = 0; % maximum current in A (determined from cell discharge curves)
        Cn; % Nominal (or average) capacity in Ah
        % Nominal (or average) voltage in V
        % Efficiency when charging [0,..,1].
        % Note: If only a total efficiency is given, set the discharging
        % efficiency eta_bd to 1.
        Vn;
    end
    properties (Access = 'protected', Hidden)
        % Internal state of health.
        % If the age model is connected directly to the object, SoH points
        % to the internal soh. Otherwise, the SoH is calculated according to
        % the sub-elements' idividual states of health.
        soh; 
        cyc; % cycleCounter object
        ageModel; % batteryAgeModel object
        soc_max; % internal soc_max is lower than external socMax if SoH < 1
        % If the external socMin is set to zero, the internal soc_min is set
        % to eps in case a dambrowskiCounter is used for cycle counting
        soc_min;
        % true/false variable for limitation of SoC in recursive iteration.
        % This is set to true when SoC limitation is active, otherwise
        % false.
        slTF = false;
        pct = uint32(0); % counter for power iteration
        sct = uint32(0); % counter for soc limiting iteration
        lastPr = 0; % last power request (for handling powerIteration through recursion)
        reH; % function handle: @gt for charging and @lt for discharging
        seH; % function handle: @ge for charging and @le for discharging
        socLim; % SoC to limit charging/discharging to (depending on charging or discharging)
        hl; % property listener (observer) for ageModel SoH
        sl; % property listener (observer) for soc
        Psd; % self-discharge energy in W
        % number of elements (in case of collection)
        % The data type is uint32
        nEl;
        % Elements (parallelELement, seriesElement or batteryCell objects)
        El;
        Cdi; % for storing Cd property in batteryCell
        % function handle for method to determine SoH
        % @sohPoint points to internal SoH
        % @sohCalc retrieves SoH from subelements
        sohPointer = @sohPoint;
    end
    properties (SetObservable, Hidden, SetAccess = 'protected')
        % State of charge (handled internally) This soc can be slightly
        % higher or lower than the public SoC property, due to the error
        % tolerances of the SoC limitation.
        soc;
    end
    properties (Hidden, SetAccess = 'protected')
       hasCells = false; % true/false flag to indicate whether circuit element has cells or not 
    end
    methods
        function b = batteryInterface(varargin)
            % BATTERYINTERFACE: Common Constructor. The properties that
            % must be instanciated may vary between subclasses. Define
            % non-optional input arguments in the subclasses and pass them
            % to this class's constructor using:
            %
            % obj@lfpBattery.batteryInterface('Name', 'Value');
            %
            % Name-Value pairs:
            %
            % sohIni        -    initial state of health [0,..,1] (default: 1)
            % socIni        -    initial state of charge [0,..,1] (default: 0.2)
            % socMin        -    minimum state of charge (default: 0.2)
            % socMax        -    maximum state of charge (default: 1)
            % ageModel      -    'none' (default), 'EO' (for event oriented
            %                    aging) or a custom age model that implements
            %                    the batteryAgeModel interface.
            %                    'LowerLevel' indicates that there is an
            %                    age model at a lower cell level.
            % cycleCounter  -    'auto' for automatic determination
            %                    depending on the ageModel (none for 'none'
            %                    and dambrowskiCounter for 'EO' or a custom
            %                    cycle counter that implements the
            %                    cycleCounter interface.

            %% parse optional inputs
            p = lfpBattery.batteryInterface.parseInputs(varargin{:});
            
            b.soh = p.Results.sohIni;
            b.socMin = p.Results.socMin;
            b.socMax = p.Results.socMax;
            b.soc = p.Results.socIni;
            b.eta_bc = p.Results.etaBC;
            b.eta_bd = p.Results.etaBD;
            b.socMin = p.Results.socMin;
            b.socMax = p.Results.socMax;
            b.soc = p.Results.socIni;
            
            % initialize age model
            warning('off', 'all')
            b.initAgeModel(varargin{:})
            warning('on', 'all')
            
        end % constructor
        function [P, I] = powerRequest(b, P, dt)
            % POWERREQUEST: MTODO: Doc
            % P:  power in W
            % dt: size of time step in S
            % MTODO: Increase precision!
            
            % set operator handles according to charge or discharge
            if P > 0 % charge
                P = b.eta_bc .* P; % limit by charging efficiency
                b.reH = @gt; % greater than
                b.seH = @ge; % greater than or equal to
                b.socLim = b.socMax;
            else % discharge
                if P == 0 % Set P to self-discharge power and limit soc to zero
                    b.socLim = eps; % eps in case dambrowskiCounter is used for cycle counting
                    P = b.Psd;
                else
                    P = b.eta_bd .* P; % limit by discharging efficiency
                    b.socLim = b.socMin;
                end
                b.reH = @lt; % less than
                b.seH = @le; % less than or equal to
            end
            if b.seH(b.socLim - b.soc, 0) % call only if SoC limit has not already been reached
                b.lastPr = P;
                [P, I, b.V, b.soc] = b.iteratePower(P, dt);
            else
                P = 0;
                I = 0;
            end
            b.slTF = false; % set SoC limitation flag false
        end % powerRequest
        function [P, I, V, soc] = iteratePower(b, P, dt)
            %ITERATEPOWER: Iteration to determine new state given a certain power.
            % The state of the battery is not changed by this method.
            % Syntax: [P, Cd, V, soc] = b.iteratePower(P, dt);
            %
            % Input arguments:
            % b      -   Subclass of the batteryInterface (object calling the method)
            % P      -   Requested charge or discharge power in W
            % dt     -   Simulation time step size in s
            %
            % Output arguments:
            % P      -   Actual charge or discharge power in W
            % Cd     -   Discharge capacity of the battery in Ah
            % V      -   Resting voltage in V
            % soc    -   State of charge [0,..,1]
            V_curr = b.V;
            I = P ./ V_curr;
            V = b.getNewVoltage(I, dt);
            Pit = I .* mean([V_curr; V]);
            err = b.lastPr - Pit;
            if abs(err) > b.pTol && b.pct < b.maxIterations
                b.pct = b.pct + 1;
                [P, I, V] = b.iteratePower(P + err, dt);
            elseif abs(I) > b.Imax + b.iTol % Limit power according to max current using recursion
                b.pct = 0;
                P = sign(I) .* b.Imax .* mean([V_curr; V]);
                b.lastPr = P;
                [P, I, V] = b.iteratePower(P, dt);
            end
            b.pct = 0;
            newCd = b.Cd - I .* dt ./ 3600;
            soc = 1 - newCd ./ b.Cn;
            if P ~= 0 % Limit power according to SoC using recursion
                os = soc - b.soc; % charged
                req = b.socLim - b.soc; % required to reach limit
                err = (req - os) ./ os;
                if (b.reH(soc, b.socLim) || b.slTF) && abs(err) > b.sTol ...
                        && b.sct < b.maxIterations
                    % MTODO: Something wrong with SoC limitation here!
                    b.sct = b.sct + 1;
                    b.slTF = true; % indicate that SoC limiting is active
                    % correct power request
                    P = b.lastPr + err .* b.lastPr;
                    b.lastPr = P;
                    [P, I, V, soc] = b.iteratePower(P, dt);
                else
                    b.sct = 0;
                    b.slTF = false;
                end
            end
        end % iteratePower
        function addCounter(b, cy)
            %ADDCOUNTER: MTODO: Doc
            if ~isempty(b.sl)
                delete(b.sl)
            end
            % Make sure the cycleCounter's lUpdate method is called
            % every time the soc property changes.
            b.sl = addlistener(b, 'soc', 'PostSet', @cy.lUpdate);
            b.ageModel.addCounter(cy);
        end
        function dischargeFit(b, V, C_dis, I, Temp, varargin)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %and adds the fitted curve to the battery model b.
            %Syntax:
            %   b.dischargeFit(V, C_dis, I, T);
            %           --> initialization of curve fit params with zeros
            %
            %   b.dischargeFit(V, C_dis, I, T, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %Input arguments:
            %   V:              Voltage (V) = f(C_dis) (from data sheet)
            %   C_dis:          Discharge capacity (Ah) (from data sheet)
            %   I:              Current at which curve was measured
            %   T:              Temperature (K) at which curve was mearured
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(9, 1)
            %
            %   x0 = [E0; Ea; Eb; Aex; Bex; Cex; x0; v0; delta] with:
            %
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            
            % add a new dischargeFit object according to the input arguments
            b.adddfit(lfpBattery.dischargeFit(V, C_dis, I, Temp, varargin{:}));
        end
        function addElements(b, varargin)
            % ADDELEMENTS: Adds elements to the collection (e. g. the
            % batteryPack, parallelElement or stringElement b. An element can
            % be a batteryCell, a parallelElement or a stringElement or a
            % user-defined element.
            %
            % Syntax: b.ADDELEMENTS(e1, e2, e3, .., en)
            %         ADDELEMENTS(b, e1, e2, e3, .., en)
            %
            % Input arguments:
            %   b        - the collection the elements are added to
            %   e1,..,en - the elements being added to the collection
            %
            % Restrictions (that return error messages)
            % - batteryCells cannot add elements.
            % - batteryPacks cannot be added to a collection of elements.
            % - adding an element to a batteryPack will replace the current
            %   element.
            for i = 1:numel(varargin)
                b.addElement(varargin{i})
            end
            b.findImax;
            b.refreshNominals;
        end
        function it = createIterator(b)
            it = batteryIterator(b);
            % MTODO: create batteryIterator & stack classes
        end
        %% setters
        function set.socMin(b, s)
            assert(s >= 0 && s <= 1, 'socMin must be between 0 and 1')
            if s == 0
                b.soc_min = eps;
            else
                b.soc_min = s;
            end
        end
        function set.socMax(b, s)
            assert(s <= 1, 'soc_max cannot be greater than 1')
            assert(s > b.socMin, 'soc_max cannot be smaller than or equal to soc_min')
            % Limit socMax by SoH
            b.soc_max = s .* b.SoH;
            b.cyc.socMax = s .* b.SoH;
        end
        function set.maxIterations(b, n)
            b.maxIterations = uint32(max(1, n));
        end
        function set.pTol(b, tol)
            b.pTol = abs(tol);
        end
        function set.sTol(b, tol)
            b.sTol = abs(tol);
        end
        function set.iTol(b, tol)
            b.iTol = abs(tol);
        end
        function set.psd(b, p)
           lfpBattery.commons.onezeroChk(p, 'self-discharge rate')
           b.Psd = p .* 1/(365.25.*86400./12) .* b.Cn ./ 3600 .* b.Vn; % 1/(month in seconds) * As * V = W
        end
        %% getters
        function a = get.SoC(b)
            s = b.soc ./ b.SoH; % SoC according to max capacity
            a = lfpBattery.commons.upperlowerlim(s, 0, b.socMax);
        end
        function a = get.Cbu(b) % useable capacity after aging
            a = (b.soc_max - b.soc_min) .* b.Cn;
        end
        function a = get.socMax(b)
            a = b.soc_max ./ b.SoH;
        end
        function a = get.socMin(b)
            a = b.soc_min;
            if a == eps
                a = 0;
            end
        end
        function s = get.SoH(b)
            s = b.sohPointer(b);
        end
    end % public methods
    
    methods (Access = 'protected')
        function initAgeModel(b, varargin)
            %INITAGEMODEL
            p = lfpBattery.batteryInterface.parseInputs(varargin{:});
            if ~isempty(b.hl)
                delete(b.hl)
            end
            am = p.Results.ageModel;
            cc = p.Results.cycleCounter;
            if ischar(am)
                if ~strcmp(am, 'EO')
                    b.cyc = lfpBattery.dummyCycleCounter;
                    b.ageModel = lfpBattery.dummyAgeModel;
                    if strcmp(am, 'LowerLevel')
                        b.sohPointer = @sohCalc; % point SoH to subcells
                    else % 'none'
                        b.sohPointer = @sohPoint; % point SoH to internal soh
                    end
                else % 'EO'
                    if strcmp(cc, 'auto')
                        cy = lfpBattery.dambrowskiCounter(b.soc, b.soc_max);
                    else
                        cy = cc;
                        cy.socMax = b.soc_max;
                    end
                    b.cyc = cy;
                    b.ageModel = lfpBattery.eoAgeModel(cy);
                    b.sohPointer = @sohPoint; % point SoH to internal SoH
                end
            else % custom age model
                if ischar(cc) % 'auto' or 'dambrowski'
                    cy = lfpBattery.dambrowskiCounter(b.soc, b.soc_max);
                else
                    cy = cc;
                end
                b.cyc = cy;
                b.ageModel = am;
                b.sohPointer = @sohPoint; % point SoH to internal SoH
            end
            % Make sure the battery model's SoH is updated every time
            % the age model's SoH changes.
            b.hl = addlistener(b.ageModel, 'SoH', 'PostSet', @b.updateSoH);
            % Make sure battery, age model and cycle counter are linked
            b.addCounter(b.cyc)
        end % initAgeModel
        function updateSoH(b, ~, event)
            maxSoC = b.socMax; % save last socMax
            b.SoH = event.AffectedObject.SoH;
            b.socMax = maxSoC; % update socMax (updated automatically in setter)
        end
        function s = refreshSoC(b)
            % REFRESHSOC: Re-calculates the SoC
            s = 1 - b.Cd ./ b.Cn;
            b.soc = s;
        end
        function addElement(b, element)
            % ADDELEMENT: Adds an element to the collection (e. g. the
            % batteryPack, parallelElement or stringElement. An element can
            % be a batteryCell, a parallelElement or a stringElement or a
            % user-defined element.
            %
            % Restrictions (that return error messages)
            % - batteryCells cannot add elements.
            % - batteryPacks cannot be added to a collection of elements.
            % - adding an element to a batteryPack will replace the current
            %   element.
            if isa(b, 'lfpBattery.batteryCell')
                error('addElement() is unsupported for batteryCell objects.')
            elseif isa(element, 'lfpBattery.batteryPack')
                error('batteryPack objects cannot be added.')
            end
            if ~element.hasCells
                error('Attempted to add element that does not contain any cells.')
            end
            if isa(b, 'lfpBattery.batteryPack')
                b.El = element;
            else
                b.nEl = uint32(sum(b.nEl) + 1); % sum() in case nEl is empty
                if isempty(b.El) || isstruct(b.El) % in case El's properties were addressed already
                    b.El = element;
                else
                    b.El(b.nEl, 1) = element;
                end
            end
            b.hasCells = true;
        end
        function s = sohPoint(b)
            % points to the internal SoC
            s = b.soh;
        end
    end
    
    methods (Static, Access = 'protected')
        function p = parseInputs(varargin)
            p = inputParser;
            addOptional(p, 'Zi', 17e-3, @isnumeric)
            addOptional(p, 'socMin', 0.2, @isnumeric)
            addOptional(p, 'socMax', 1, @isnumeric)
            addOptional(p, 'socIni', 0.2, @(x) ~lfpBattery.commons.ge1le0(x))
            addOptional(p, 'sohIni', 1, @(x) ~lfpBattery.commons.ge1le0(x))
            addOptional(p, 'etaBC', 0.97, @isnumeric)
            addOptional(p, 'etaBD', 0.97, @isnumeric)
            validModels = {'auto', 'dambrowski'};
            type = 'lfpBattery.cycleCounter';
            addOptional(p, 'cycleCounter', 'auto', ...
                @(x) lfpBattery.batteryInterface.validateAM(x, validModels, type))
            validModels = {'none', 'EO', 'LowerLevel'};
            type = 'lfpBattery.batteryAgeModel';
            addOptional(p, 'ageModel', 'none', ...
                @(x) lfpBattery.batteryInterface.validateAM(x, validModels, type))
            parse(p, varargin{:});
        end
        function tf = validateAM(x, validModels, type)
            % validates age model & cycle counter inputs
            if ischar(x)
                tf = any(validatestring(x, validModels));
            else
                tf = lfpBattery.commons.itfcmp(x, type);
            end
        end
    end
    
    methods (Abstract)
        % GETNEWVOLTAGE: Returns the new voltage according to a current and a
        % time step size
        v = getNewVoltage(b, I, dt);
        addcurves(b, d, type); % adds a collection of discharge curves
    end % abstract methods
    
    methods (Abstract, Access = 'protected')
        i = findImax(b); % determins the maximum current according to the discharge curves and/or the topology
        charge(b, Q); % For dis/charging a certain capacity Q in Ah
        refreshNominals(b); % Refresh nominal voltage and capacity (called whenever a new element is added)
        s = sohCalc(b); % Determines the SoH
    end
end

