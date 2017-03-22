classdef (Abstract) batteryInterface < lfpBattery.composite %& lfpBattery.gpuCompatible
    %BATTERYINTERFACE: Abstract class / interface for creating battery
    %models. This is the common interface for batteryPacks, batteryCells,
    %seriesElements, parallelElements, simpleSE and simplePE, ...
    %
    %SEE ALSO: lfpBattery.batteryPack lfpBattery.batteryCell
    %          lfpBattery.batCircuitElement lfpBattery.seriesElement
    %          lfpBattery.seriesElementPE lfpBattery.seriesElementAE
    %          lfpBattery.parallelElement lfpBattery.simplePE
    %          lfpBattery.simpleSE
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    properties
        % Maximum number of iterations in iteratePower() and iterateCurrent() methods.
        % The methods powerRequest() and powerIterator() iterate through
        % currents in order to find the current / voltage combination
        % required for a given power. Also, the SoC and current limitations
        % are handled using similar iterations. Set the maximum number of
        % iterations with the maxIterations property.
        % Reducing this number can decrease the simulation time, but can
        % also reduce the accuracy.
        maxIterations = uint32(1e6); 
        % Tolerance for the power iteration in W.
        % Increasing this number can decrease the simulation time, but can
        % also reduce the accuracy of the power requests.
        pTol = 1e-3; 
        % Tolerance for SoC limitation iteration.
        % Increasing this number can decrease the simulation time, but can
        % also reduce the accuracy of the SoC limitation.
        sTol = 1e-6;
    end
    properties (Dependent, Access = 'protected')
        Psd; % self-discharge energy in W
    end
    properties (Abstract, Dependent, SetAccess = 'protected')
        % Internal impedance in Ohm.
        % The internal impedance is currently not used as a physical
        % parameter. However, it is used in the circuit elements
        % (seriesElement/parallelElement) to determine the distribution
        % of currents and voltages.
        Zi;
    end
    properties (Dependent, SetAccess = 'protected')
        SoH; % State of health [0,..,1]
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
    properties (Abstract, Dependent, SetAccess = 'protected')
        % Discharge capacity in Ah (Cd = 0 if SoC = 1).
        % The discharge capacity is given by the nominal capacity Cn and
        % the current capacity C at SoC.
        % Cd = Cn - C
        Cd;
        % Current capacity level in Ah.
        C;
    end
    properties (Abstract, Dependent)
        V; % Resting voltage in V
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
    end
    properties (SetAccess = 'protected')
        ImaxD = 0; % maximum discharging current in A (determined from cell discharge curves)
        ImaxC = 0; % maximum charging current in A (determined from cell CCCV curves)
        Cn; % Nominal (or average) capacity in Ah
        % Nominal (or average) voltage in V
        % Efficiency when charging [0,..,1].
        % Note: If only a total efficiency is given, set the discharging
        % efficiency eta_bd to 1.
        Vn;
        % Efficiency when charging [0,..,1].
        % Note: Set eta_bd to 1 if only a total efficiency is given.
        eta_bc;
        % Efficiency when discharging [0,..,1].
        % Note: Set this property to 1 if only a total efficiency is given.
        eta_bd;
        % Self discharge rate in 1/month [0,..,1] (default: 0)
        % By default, the self-discharge of the batteries is neglected.
        psd;
    end
    properties (Access = 'protected', Hidden)
        Imax; % Maximum current (dependent on charging or discharging)
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
        lastIr = 0; % last current request (for handling currentIteration through recursion)
        reH; % function handle: @gt for charging and @lt for discharging
        seH; % function handle: @ge for charging and @le for discharging
        socLim; % SoC to limit charging/discharging to (depending on charging or discharging)
        hl; % property listener (observer) for ageModel SoH
        sl; % property listener (observer) for soc
        % number of elements (in case of collection)
        % The data type is uint32
        nEl;
        rnEl; % reciprocal of nEl as double
        % Elements (parallelELement, seriesElement or batteryCell objects)
        El;
        Cdi; % for storing Cd property in batteryCell
        % function handle for method to determine SoH
        % @sohPoint points to internal SoH
        % @sohCalc retrieves SoH from subelements
        sohPointer = @sohPoint;
        % cache(1) = V_curr in iteratePower
        % cache(2) = self-discharge
        cache = cell(2, 1);
        clBMS = false; % Logical flag for whether BMS is active for charge current limiting
        cvL = cell(1, 1); % cell array of event listeners (observers) for batteryCell's CV event
        ccL = cell(1, 1); % cell array of event listeners (observers) for batteryCell's CC event
        getNewVoltage; % Function handle to method for retrieving new voltage
        wFit; % cache for cycleCurveFit objects (in case they are added before age model is initialized)
    end
    properties (SetObservable, Hidden, SetAccess = 'protected')
        % State of charge (handled internally) This soc can be slightly
        % higher or lower than the public SoC property, due to the error
        % tolerances of the SoC limitation.
        soc;
    end
    properties (Hidden, SetAccess = 'protected')
       % true/false flag to indicate whether circuit element has cells or
       % not. Set this flag to true if a batteryCell is added to a
       % composite branch, such as a parallelElement or a seriesElement
       hasCells = false;
       isCell = false; % set this to true for cell objects, such as batteryCell.
    end
    properties (Hidden, Constant, GetAccess = 'protected')
        secsToHours = 1 / 3600;
    end
    methods
        function b = batteryInterface(varargin)
            % BATTERYINTERFACE: Constructor. The properties that
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
            b.psd = p.Results.psd;
            lfpBattery.commons.onezeroChk(b.psd, 'self-discharge rate')
            
            % initialize age model
            warning('off', 'all')
            b.initAgeModel(varargin{:})
            warning('on', 'all')
            
        end % constructor
        function [P, V, I] = powerRequest(b, P, dt)
            % POWERREQUEST: Requests a power in W (positive for charging,
            % negative for discharging) from the battery.
            %
            % Syntax: [P, V, I] = b.POWERREQUEST(P, dt);
            %         [P, V, I] = POWERREQUEST(b, P, dt);
            %
            % Input arguments:
            % b     - battery object
            % P     - Power in W (positive for charging, negative for
            %         discharging)
            % dt    - Size of time step in s
            % 
            % Output arguments:
            % P     - DC power (in W) that was used to charge the battery (positive)
            %         or DC power (in W) that was extracted from the
            %         battery (negative).
            % V     - The resting voltage in V of the battery at the end of
            %         the time step.
            % I     - The current with which the battery was charged (positive) or discharged
            %         (negative) in A. 
            
            % set operator handles according to charge or discharge
            sd = false; % self-discharge flag
            if P > 0 % charge
                b.getNewVoltage = @getNewChargeVoltage; % Handle for voltage determination
                if b.clBMS % charge limitation
                    b.findImaxC;
                    b.clBMS = false;
                end
                b.Imax = b.ImaxC;
                eta = b.eta_bc; % limit by charging efficiency
                b.reH = @gt; % greater than
                b.seH = @ge; % greater than or equal to
                b.socLim = b.socMax;
            else % discharge
                b.getNewVoltage = @getNewDischargeVoltage;
                b.Imax = b.ImaxD;
                if P == 0 % Set P to self-discharge power and limit soc to zero
                    eta = 1; % Do not include efficiency for self-discharge
                    b.socLim = eps; % eps in case dambrowskiCounter is used for cycle counting
                    P = b.Psd;
                    sd = true;
                else
                    % limit by discharging efficiency (more power is
                    % required to get the requested amount)
                    eta = 1 / b.eta_bd; 
                    b.socLim = b.socMin;
                end
                b.reH = @lt; % less than
                b.seH = @le; % less than or equal to
            end
            P = eta * P;
            P0 = P; % save initial request
            if b.socChk % call only if SoC limit has not already been reached
                b.lastPr = P;
                [P, I, V, ~] = b.iteratePower(P, dt);
                if sign(P) ~= sign(P0) || sd
                    % This prevents false power flows in case of changes to
                    % the SoC limitations
                    % OR
                    % return zero for self-discharge, as this is only internal
                    [P, I, V] = b.nullRequest;
                else
                    b.V = V;
                    b.charge(I * dt * b.secsToHours) % charge with Q
                    b.refreshSoC; % re-calculates element-level SoC as a total
                end
            else
                [P, I, V] = b.nullRequest;
            end
            b.slTF = false; % set SoC limitation flag false
            if sd % Do not return power if self discharge occured
                P = 0;
            else
                % Return power required to charge the battery or respectively
                % the power retrieved from discharging the battery
                P = P / eta;
            end
        end % powerRequest
        function [P, I, V, soc] = iteratePower(b, P, dt)
            %ITERATEPOWER: Iteration to determine new state given a certain power.
            % The state of the battery is not changed by this method.
            %
            % Syntax: [P, I, V, soc] = b.ITERATEPOWER(P, dt);
            %         [P, I, V, soc] = ITERATEPOWER(b, P, dt);
            %
            % Input arguments:
            % b      -   battery object
            % P      -   Requested charge or discharge power in W
            % dt     -   Simulation time step size in s
            %
            % Output arguments:
            % P      -   Actual charge (+) or discharge (-) power in W
            % I      -   Charge (+) or discharge (-) current in A
            % V      -   Resting voltage in V
            % soc    -   State of charge [0,..,1]
            if isempty(b.cache{1})
                b.cache{1} = b.V;
            end
            I = P / b.cache{1};
            V = b.getNewVoltage(b, I, dt);
            Pit = I * sum([b.cache{1}; V]) * 0.5;
            err = b.lastPr - Pit;
            if abs(err) > b.pTol && b.pct < b.maxIterations
                b.pct = b.pct + 1;
                [P, I, V] = b.iteratePower(P + err, dt);
            else
                P = b.lastPr;
            end
            % Limit power according to max current using recursion
            if abs(I) > b.Imax
                I = lfpBattery.commons.upperlowerlim(-b.ImaxD, b.ImaxC, I);
                b.lastIr = I;
                I = b.iterateCurrent(I, dt);
                V = b.getNewVoltage(b, I, dt);
                P = I * sum([b.cache{1}; V]) * 0.5;
            end
            b.pct = 0;
            newC = b.dummyCharge(I * dt * b.secsToHours);
            soc = newC / b.Cn;
            if P ~= 0 % Limit power according to SoC using recursion
                [limitReached, err] = b.socLimChk(soc);
                if limitReached
                    b.sct = b.sct + 1;
                    b.slTF = true; % indicate that SoC limiting is active to prevent switching the sign of the power
                    % correct power request
                    P = b.lastPr + err * b.lastPr;
                    b.lastPr = P;
                    [P, I, V, soc] = b.iteratePower(P, dt);
                end
            end
            b.sct = 0;
            b.slTF = false;
            b.cache{1} = []; % clear cache
        end % iteratePower
        function [P, V, I] = currentRequest(b, I, dt)
            % CURRENTREQUEST: Requests a current in A (positive for charging,
            % negative for discharging) from the battery.
            %
            % Syntax: [P, V, I] = b.CURRENTREQUEST(I, dt);
            %         [P, V, I] = CURRENTREQUEST(b, I, dt);
            %
            % Input arguments:
            % b     - battery object
            % I     - DC current in A (positive for charging, negative for
            %         discharging)
            % dt    - Size of time step in s
            % 
            % Output arguments:
            % P     - DC power in W that went into (positive) or came out of (negative) the battery.
            % V     - The resting voltage in V of the battery at the end of
            %         the time step.
            % I     - The DC current in A which was used to charge (positive) the battery or
            %         which was discharged (negative) from the battery.
            if I > 0 % charge
                b.getNewVoltage = @getNewChargeVoltage; % Handle to voltage calculatin method
                if b.clBMS % charge limitation
                    b.findImaxC;
                    b.clBMS = false;
                end
                b.reH = @gt; % greater than
                b.seH = @ge; % greater than or equal to
                b.socLim = b.socMax;
                eta = b.eta_bc; % limit: charging efficiency
            else
                b.getNewVoltage = @getNewDischargeVoltage;
                if I == 0
                    [P, V, I] = b.powerRequest(0, dt); % self-discharge is handled by powerRequest
                    return
                else
                    b.socLim = b.socMin;
                    % limit: discharging efficiency
                    eta = 1 / b.eta_bd; % More required to retrieve request
                end
                b.reH = @lt; % less than
                b.seH = @le; % less than or equal to
            end
            if b.socChk % If charging is possible
                I = I * eta;
                I0 = I; % save initial request
                I = lfpBattery.commons.upperlowerlim(I, -b.ImaxD, b.ImaxC); % limit to max current
                b.lastIr = I;
                I = b.iterateCurrent(I, dt);
                if sign(I) == sign(I0)
                    V = b.getNewVoltage(b, I, dt);
                    P = I * sum([b.V; V]) * 0.5;
                    b.V = V;
                    b.charge(I * dt * b.secsToHours) % charge with Q
                    b.refreshSoC; % re-calculates element-level SoC as a total
                else
                    [P, I, V] = b.nullRequest;
                end
                I = I / eta; % Return what was taken from the load or discharged
            else
                [P, I, V] = b.nullRequest;
            end
            b.slTF = false;
        end % currentRequest
        function [I, soc] = iterateCurrent(b, I, dt)
            %ITERATECURRENT: Iteration to determine new state given a certain current.
            % The state of the battery is not changed by this method.
            %
            % Syntax: [I, soc] = b.ITERATECURRENT(P, dt);
            %         [I, soc] = ITERATECURRENT(b, P, dt);
            %
            % Input arguments:
            % b      -   battery object
            % P      -   Requested charge or discharge power in W
            % dt     -   Simulation time step size in s
            %
            % Output arguments:
            % I      -   Actual charge (+) or discharge (-) current in A
            % soc    -   State of charge [0,..,1]
            newC = b.dummyCharge(I * dt * b.secsToHours);
            soc = newC / b.Cn;
            [limitReached, err] = b.socLimChk(soc);
            if limitReached
                b.sct = b.sct + 1;
                b.slTF = true; % indicate that SoC limiting is active to prevent switching the sign of the power
                % correct current request
                I = b.lastIr + err * b.lastIr;
                b.lastIr = I;
                [I, soc] = b.iterateCurrent(I, dt);
            end
            b.sct = 0;
            b.slTF = false;
        end % iterateCurrent
        function addCounter(b, cy)
            %ADDCOUNTER: Registers a cycleCounter object cy as an observer
            %of the battery b. It also registers cy as an observer of the
            %battery's age model.
            %An age model must be linked to the battery in order for this
            %method to be callable.
            %Usage of this method is not recommended. Use initAgeModel
            %instead.
            %
            %SEE ALSO: lfpBattery.batteryInterface.initAgeModel
            %
            %Syntax. b.ADDCOUNTER(cy)
            %        ADDCOUNTER(b, cy)
            if ~lfpBattery.commons.itfcmp(b.ageModel, 'lfpBattery.batteryAgeModel')   
                error('No age model registered yet.')
            end
            if ~isempty(b.sl)
                delete(b.sl)
            end
            % Make sure the cycleCounter's lUpdate method is called
            % every time the soc property changes.
            b.sl = addlistener(b, 'soc', 'PostSet', @cy.lUpdate);
            b.ageModel.addCounter(cy);
        end % addCounter
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
            %   I:              Current (A) at which curve was measured
            %   T:              Temperature (K) at which curve was mearured
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(8, 1)
            %
            %   x0 = [E0; Ea; Eb; x0; v0; delta; Aex; Bex] with:
            %
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %   Aex, Bex:       Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq' (default) - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - a combination (lsq, then fmin)
            
            % add a new dischargeFit object according to the input arguments
            b.addcurves(lfpBattery.dischargeFit(V, C_dis, I, Temp, varargin{:}));
        end % dischargeFit
        function chargeFit(b, V, C_dis, I, Temp, varargin)
            %CHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %charge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %and adds the fitted curve to the battery model b.
            %Syntax:
            %   b.chargeFit(V, C_dis, I, T);
            %           --> initialization of curve fit params with zeros
            %
            %   b.chargeFit(V, C_dis, I, T, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %Input arguments:
            %   V:              Voltage (V) = f(C_dis) (from data sheet)
            %   C_dis:          Discharge capacity (Ah) (from data sheet)
            %   I:              Current (A) at which curve was measured
            %   T:              Temperature (K) at which curve was mearured
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(8, 1)
            %
            %   x0 = [E0; Ea; Eb; x0; v0; delta; Aex; Bex] with:
            %
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %   Aex, Bex:       Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq' (default) - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - a combination (lsq, then fmin)
            
            % add a new dischargeFit object according to the input arguments
            b.addcurves(lfpBattery.dischargeFit(V, C_dis, I, Temp, varargin{:}), 'charge');
        end % chargeFit
        function cycleFit(b, DoDN, N, varargin)
            %CYCLEFIT creates a fit object for a cycles to failure vs. DoD curve.
            %
            %The default fitting class used is lfpBattery.woehlerFit.
            %The fitted curve is added to the battery model b.
            %
            %   d = b.CYCLEFIT(DoD, N) 
            %           --> creates a fit for the function N(DoD)
            %
            %   d = b.CYCLEFIT(DoD, N, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(2, 1)
            %
            %   x0 = [p1; p2]
            %
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            %
            %   'fitClass'      Class to be used for curve fitting: 
            %                   'woehlerFit', 'nrelcFit' or 'deFit'
            p = inputParser;
            validClasses = {'woehlerFit', 'nrelcFit', 'deFit'};
            addOptional(p, 'fitClass', 'woehlerFit', @(x) validatestring(x, validClasses))
            addOptional(p, 'x0', 'auto')
            addOptional(p, 'mode', 'both')
            switch p.Results.fitClass
                case 'woehlerFit'
                    fitClass = @lfpBattery.woehlerFit;
                case 'nrelcFit'
                    fitClass = @lfpBattery.nrelcFit;
                case 'deFit'
                    fitClass = @lfpBattery.deFit;
                otherwise
                    error('Unexpected fit class.')
            end
            % Create new fit object according to input arguments
            if strcmp(p.Results.x0, 'auto')
                fit = fitClass(DoDN, N, 'mode', p.Results.mode);
            else
                fit = fitClass(DoDN, N, 'x0', p.Results.x0, 'mode', p.Results.mode);
            end
            % Add fit object to pack
            b.addcurves(fit, 'cycleLife')
        end % woehlerFit
        function cccvFit(b, varargin)
            %CCCVFIT: Creates a linear curve fit of the CV phase of a CCCV
            %(constant current, constant voltage) charging curve: Imax = f(SoC)
            %where SoC is the state of charge and Imax is the maximum
            %current and adds it to the battery pack b.
            %
            %Syntax: c = b.CCCVFIT(soc, iMax);
            %        c = b.CCCVFIT(soc, iMax, socMax);
            %
            %Input arguments:
            %   soc     - state of charge [0..1].
            %   iMax    - maximum current in A at soc.
            %   socMax  - (optional) maximum SoC at the end of the CV
            %             phase (default: 1).
            %
            %   The input arguments soc and iMax can be scalars or vectors
            %   of the same size.
            %   Note that only the first value is used for the fit.
            %   However, it may be advisable to include data for multiple
            %   points of the curve to validate that the correspondece is
            %   in fact linear.
           
            b.addcurves(lfpBattery.cccvFit(varargin{:}), 'cccv')
        end % cccvFit
        function addElements(b, varargin)
            % ADDELEMENTS: Adds elements to the collection (e. g. the
            % batteryPack, parallelElement or stringElement b. An element can
            % be a batteryCell, a parallelElement, a stringElement subclass,
            % a simplePE, a simpleSE or a user-defined element that implements the
            % batteryInterface.
            %
            % Syntax: b.ADDELEMENTS(e1, e2, e3, .., en)
            %         ADDELEMENTS(b, e1, e2, e3, .., en)
            %
            % Input arguments:
            %   b        - The collection the elements are added to.
            %   e1,..,en - The elements being added to the collection.
            %              These can also be arrays of elements.
            %
            % Restrictions (that return error messages)
            % - batteryCells cannot add elements.
            % - batteryPacks cannot be added to a collection of elements.
            % - adding an element to a batteryPack will replace the current
            %   element.
            for i = 1:numel(varargin)
                el = varargin{i};
                for j = 1:numel(el) % In case arrays are added
                    b.addElement(el(j))
                end
            end
            b.findImaxD;
            b.findImaxC;
            b.refreshNominals;
        end
        function it = createIterator(b, el)
            %CREATEITERATOR: Returns an iterator for iterating through the
            %collection's battery cells.
            %
            %SEE ALSO: lfpBattery.iterator
            %MTODO: Finish doc
            if nargin == 1
                it = lfpBattery.batteryIterator(b.createIterator(b.El), b);
            else
                it = lfpBattery.vIterator(el);
            end
        end
        function initAgeModel(b, varargin)
            %INITAGEMODEL: Initializes the age model of a battery b.
            %
            %Syntax: b.INITAGEMODEL(b, 'OptionName', 'OptionValue')
            %
            %Options:
            %
            % 'ageModel'     -    'none' (default), 'EO' (for event oriented
            %                     aging) or a custom age model that implements
            %                     the batteryAgeModel interface.
            %                     'LowerLevel' indicates that there is an
            %                     age model at a lower cell level.
            % 'cycleCounter' -    'auto' for automatic determination
            %                     depending on the ageModel (none for 'none'
            %                     and dambrowskiCounter for 'EO' or a custom
            %                     cycle counter that implements the
            %                     cycleCounter interface.
            if nargin == 2
                error('Not enough input arguments.')
            end
            p = lfpBattery.batteryInterface.parseInputs(varargin{:});
            if ~isempty(b.hl)
                delete(b.hl)
            end
            am = p.Results.ageModel;
            cc = p.Results.cycleCounter;
            if ischar(am)
                if ~strcmp(am, 'EO')
                    if ~ischar(cc)
                        warning(['A cycleCounter was added, but no ageModel was specified. ', ...
                            'Replacing the cycleCounter with a dummyCycleCounter.'])
                    end
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
                    if ~isempty(b.wFit)
                        b.ageModel.wFit = b.wFit;
                    end
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
                if ~isempty(b.wFit)
                    if isempty(am.wFit)
                        b.ageModel.wFit = b.wFit;
                    else
                        warning(['Battery and age model both have a cycle life curve fit. ', ...
                            'The battery''s fit has been replaced with the age model''s fit.'])
                    end
                end
                b.sohPointer = @sohPoint; % point SoH to internal SoH
            end
            % Make sure the battery model's SoH is updated every time
            % the age model's SoH changes.
            b.hl = addlistener(b.ageModel, 'SoH', 'PostSet', @b.updateSoH);
            % Make sure battery, age model and cycle counter are linked
            b.addCounter(b.cyc)
        end % initAgeModel
        function randomizeDC(b)
            % RANDOMIZEDC: Iterates through each battery cell's discharge
            % curve fit and resets the x parameters with randomly generated numbers,
            % causing the curves to be re-fitted.
            %
            % WARNING: By default, only one curve fit handle is used for
            % all the cells in a model to save memory. Calling this function
            % creates a deep copy of the curve fit handle for each cell and
            % could result in high memory usage.
            %
            % Calling this method on an object that holds only one cell has no effect.
            it = b.createIterator;
            while it.hasNext
                cell = it.next;
                cell.randomizeDC; % Pass on to each battery cell
            end
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
            b.soc_max = s * b.SoH;
            b.cyc.socMax = s * b.SoH;
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
        %% getters
        function a = get.SoC(b)
            s = b.soc / b.SoH; % SoC according to max capacity
            a = lfpBattery.commons.upperlowerlim(s, 0, b.socMax);
        end
        function a = get.Cbu(b) % useable capacity after aging
            a = (b.soc_max - b.soc_min) .* b.Cn;
        end
        function a = get.socMax(b)
            a = b.soc_max / b.SoH;
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
        function p = get.Psd(b)
            if isempty(b.cache{2})
                b.cache{2} = - abs(b.psd * 1/(365.25*86400/12) * (b.Cn / 3600) * b.Vn); % 1/(month in seconds) * As * V = W
            end
           p = b.cache{2};
        end
        function clearCCCVlisteners(b)
            % Deletes the CC and CV event listeners
            for i = 1:numel(b.cvL)
                try delete(b.cvL{i}); catch; end
                try delete(b.ccL{i}); catch; end
            end
            b.cvL = cell(1, 1);
            b.ccL = cell(1, 1);
        end
    end % public methods
    
    methods (Access = 'protected')
        function setVoltage(b, v)
            b.V = v;
        end
        function updateSoH(b, ~, event)
            % UPDATESOH: Updates the SoH. This method is called when
            % notified by a batteryAgeModel.
            maxSoC = b.socMax; % save last socMax
            b.SoH = event.AffectedObject.SoH;
            b.socMax = maxSoC; % update socMax (updated automatically in setter)
        end
        function s = refreshSoC(b)
            % REFRESHSOC: Re-calculates the SoC
            s = b.C / b.Cn;
            b.soc = s;
        end
        function addElement(b, element)
            % ADDELEMENT: Adds an element to the collection (e. g. the
            % batteryPack, parallelElement or stringElement. An element can
            % be a batteryCell, a parallelElement, a stringElement subclass,
            % a simplePE, a simpleSE or a user-defined element that implements the
            % batteryInterface.
            %
            % Restrictions (that return error messages)
            % - batteryCells cannot add elements.
            % - batteryPacks cannot be added to a collection of elements.
            % - adding an element to a batteryPack will replace the current
            %   element.
            lfpBattery.commons.validateInterface(element, 'lfpBattery.batteryInterface')
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
                b.nEl = uint32(sum(b.nEl) + 1); % sum() in case dnEl is empty
                b.rnEl = 1 / double(b.nEl);
                if isempty(b.El) || isstruct(b.El) % in case El's properties were addressed already
                    b.El = element;
                else
                    b.El(b.nEl, 1) = element;
                end
                element.clearCCCVlisteners;
                it = element.createIterator;
                while it.hasNext
                    bat = it.next;
                    b.cvL{end+1, 1} = addlistener(bat, 'CV', @b.setClBMSflag);
                    b.ccL{end+1, 1} = addlistener(bat, 'CC', @b.setClBMSflag);
                end
            end
            b.hasCells = true;
        end
        function setClBMSflag(b, ~, ~)
            % SETCLBMSFLAG: Sets the clBMS flag to true, causing the charge
            % limitation to be re-calculated in the next charging time
            % step.
            b.clBMS = true;
        end
        function s = sohPoint(b)
            % points to the internal SoC
            s = b.soh;
        end
        function tf = socChk(b)
            % Makes sure SoC is not close to limit
            tf = abs(b.socLim - b.soc) > b.sTol;
        end
        function [tf, err] = socLimChk(b, soc)
            os = soc - b.soc; % charged
            req = b.socLim - b.soc; % required to reach limit
            err = (req - os) ./ os;
            tf = (b.reH(soc, b.socLim) || b.slTF) && abs(err) > b.sTol ...
                && b.sct < b.maxIterations;
        end
        function [P, I, V] = nullRequest(b)
            P = 0;
            I = 0;
            V = b.V;
        end
        % Overload saveobj to print handle link warning
        function b = saveobj(b)
            lfpBattery.commons.warnHandleSave(b)
        end
        % gpuCompatible methods
        % These methods are currently unsupported and may be removed in a
        % future version.
        %{
        function setsubProp(obj, fn, val)
            obj.(fn) = val;
        end
        function val = getsubProp(obj, fn)
            val = obj.(fn);
        end
        %}
    end
    
    methods (Static, Access = 'protected')
        function p = parseInputs(varargin)
            % Returns an input parser with the results as specified by
            % varargin.
            p = lfpBattery.batteryInterface.bInputParser;
            parse(p, varargin{:});
        end
        function p = bInputParser()
            % Creates an input parser with optional inputs for all
            % batteryInterface objects
            p = inputParser;
            addOptional(p, 'Zi', 17e-3, @isnumeric)
            addOptional(p, 'socMin', 0.2, @isnumeric)
            addOptional(p, 'socMax', 1, @isnumeric)
            addOptional(p, 'socIni', 0.2, @(x) ~lfpBattery.commons.ge1le0(x))
            addOptional(p, 'sohIni', 1, @(x) ~lfpBattery.commons.ge1le0(x))
            addOptional(p, 'etaBC', 0.97, @isnumeric)
            addOptional(p, 'etaBD', 0.97, @isnumeric)
            addOptional(p, 'psd', 0, @isnumeric)
            validModels = {'auto', 'dambrowski'};
            type = 'lfpBattery.cycleCounter';
            addOptional(p, 'cycleCounter', 'auto', ...
                @(x) lfpBattery.batteryInterface.validateAM(x, validModels, type))
            validModels = {'none', 'EO', 'LowerLevel'};
            type = 'lfpBattery.batteryAgeModel';
            addOptional(p, 'ageModel', 'none', ...
                @(x) lfpBattery.batteryInterface.validateAM(x, validModels, type))
        end
        function tf = validateAM(x, validModels, type)
            % validates age model & cycle counter inputs
            if ischar(x)
                tf = any(validatestring(x, validModels));
            else
                tf = lfpBattery.commons.itfcmp(x, type);
            end
        end
    end % Static, protected methods
    
    methods (Abstract)
        % GETNEWDISCHARGEVOLTAGE: Returns the new voltage according to a discharging current and a
        % time step size.
        % 
        % Syntax:   v = b.GETNEWDISCHARGEVOLTAGE(I, dt);
        %           v = GETNEWDISCHARGEVOLTAGE(b, I, dt);
        %
        % Input arguments:
        %   b   - battery object
        %   I   - current in A
        %   dt  - time step size in s
        v = getNewDischargeVoltage(b, I, dt);
        % GETNEWCHARGEVOLTAGE: Returns the new voltage according to a charging current and a
        % time step size.
        % 
        % Syntax:   v = b.GETNEWCHARGEVOLTAGE(I, dt);
        %           v = GETNEWCHARGEVOLTAGE(b, I, dt);
        %
        % Input arguments:
        %   b   - battery object
        %   I   - current in A
        %   dt  - time step size in s
        v = getNewChargeVoltage(b, I, dt);
        % ADDCURVES: Adds a collection of discharge curves or a cycle
        % life curve to the battery.
        %
        % Syntax: b.ADDCURVES(d, type)
        %         ADDCURVES(b, d, type)
        %
        % Input arguments
        %   b    - battery object to add the curves to
        %   d    - curve fit object (must implement the curveFitInterface or
        %          the curvefitCollection interface)
        %   type - String indicating which type of curve is to be added.
        %          'discharge' (default) for a discharge curve, 'cycleLife' for a
        %          cycleLife cell, 'charge' for a charge curve and 'cccv'
        %          for a CCCV curve
        %
        % SEE ALSO: lfpBattery.curveFitInterface
        % lfpBattery.curvefitCollection lfpBattery.dischargeCurves
        % lfpBattery.dischargeFit lfpBattery.woehlerFit
        addcurves(b, d, type);
        % GETTOPOLOGY: Returns the number of parallel elements np and the
        % number of elements in series ns in a battery object b.
        %
        % Syntax:   [np, ns] = b.GETTOPOLOGY;
        %           [np, ns] = GETTOPOLOGY(b);
        %
        % Note that this method does not account for uneven topologies
        % e. g. a parallel element containin string elements with different
        % numbers of cells. For each sub-element, the maximum number of
        % cells is returned.
        [np, ns] = getTopology(b);
        charge(b, Q); % For dis/charging a certain capacity Q in Ah
        c = dummyCharge(b, Q); % returns the new capacity after charge/discharge without altering the object's properties
        % determins the maximum discharging current according to the discharge curves and the topology
        % 
        % Syntax: i = b.findImaxD;
        i = findImaxD(b);
        % determins the maximum charging current according to the cccv curve and the topology
        % 
        % Syntax: i = b.findImaxC;
        i = findImaxC(b);
    end % abstract methods
    
    methods (Abstract, Access = 'protected')
        refreshNominals(b); % Refresh nominal voltage and capacity (called whenever a new element is added)
        s = sohCalc(b); % Determines the SoH
    end
    
    methods (Static)
        % Overload loadobj to print handle link warning
        function b = loadobj(b)
            lfpBattery.commons.warnHandleSave(b)
        end
    end
end 

