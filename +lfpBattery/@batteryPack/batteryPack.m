classdef batteryPack < lfpBattery.batteryInterface
    %BATTERYPACK: Cell-resolved model of a lithium ion battery pack.
    %
    %
    % BATTERYPACK Methods:
    % powerRequest      - Requests a power in W (positive for charging,
    %                     negative for discharging) from the battery.
    % iteratePower      - Iteration to determine new state given a certain power.
    % currentRequest    - Requests a current in A (positive for charging,
    %                     negative for discharging) from the battery.
    % iterateCurrent    - Iteration to determine new state given a certain current.
    % addCounter        - Registers a cycleCounter object as an observer.
    % dischargeFit      - Uses Levenberg-Marquardt algorithm to fit a
    %                     discharge curve.
    % initAgeModel      - Initializes the age model of the battery.
    % getNewVoltage     - Returns the new voltage according to a current and a
    %                     time step size.
    % addcurves         - Adds a collection of discharge curves or a cycle
    %                     life curve to the battery.
    % randomizeDC       - Slight randomization of each cell's discharge
    %                     curve fits.
    % digitizeTool      - (static) Opens a GUI for digitizing discharge curves and
    %                     cycle life curves (requires JAVA).
    % gui               - (static) Opens a GUI for creating a batteryPack model.
    %                     (requires JAVA)
    %
    %
    % BATTERYPACK Properties:
    % AgeModelLevel     - Level of the age model ('Cell or 'Pack')
    % C                 - Current capacity level in Ah.
    % Cbu               - Useable capacity in Ah.
    % Cd                - Discharge capacity in Ah (Cd = 0 if SoC = 1).
    % Cn                - Nominal (or average) capacity in Ah.
    % eta_bc            - Efficiency when charging [0,..,1].
    % eta_bd            - Efficiency when discharging [0,..,1].
    % Imax              - Maximum current in A.
    % psd               - Self discharge rate in 1/month [0,..,1].
    % SoC               - State of charge [0,..,1].
    % socMax            - Maximum SoC (default: 1).
    % socMin            - Minimum SoC (default: 0.2).
    % SoH               - State of health [0,..,1].
    % V                 - Resting voltage in V.
    % Vn                - Nominal (or average) voltage in V.
    % Zi                - Internal impedance in Ohm.
    % nP                - number of parallel elements.
    % nS                - number of elements in series.
    %
    %
    % BATTERYPACK Settable Properties:
    % maxIterations     - Maximum number of iterations in iteratePower()
    %                     and iterateCurrent() methods.
    % pTol              - Tolerance for the power iteration in W.
    % sTol              - Tolerance for SoC limitation iteration.
    % iTol              - Tolerance for current limitation iteration in A.
    %
    %
    %Syntax:
    %       b = BATTERYPACK(Cp, Vp, Cc, Vc);
    %           Initializes a battery pack with the nominal cell voltae Vc and the
    %           nominal cell capacity Cc. The cells are arranged as strings of
    %           parallel cells in such a way that the pack's nominal voltage Vp
    %           and capacity Cp come as close as possible to the inputs Cp and Vp.
    %
    %       b = BATTERYPACK(np, ns, Cc, Vc);
    %           np and ns must be integers for this syntax, otherwise the above syntax
    %           is interpreted!
    %           Initializes a battery pack with the nominal cell voltae Vc and the
    %           nominal cell capacity Cc. The cells are arranged as ns strings of
    %           parallel elements with np parallel cells. The pack's nominal capacity
    %           depends on the cell voltage Vc and on the number of parallel cells np.
    %           The pack's nominal voltage depends on the cell voltage Vc and on the
    %           number of elements per string ns.
    %
    %       b = BATTERYPACK(np, ns, Cc, Vc, 'Setup', 'Manual');
    %           Initializes a battery pack with the nominal cell voltae Vc and the
    %           nominal cell capacity Cc. The cells are arranged as ns strings of
    %           parallel elements with np parallel cells. The pack's nominal capacity
    %           depends on the cell voltage Vc and on the number of parallel cells np.
    %           The pack's nominal voltage depends on the cell voltage Vc and on the
    %           number of elements per string ns.
    %           np and ns can be any numerical data type using this syntax.
    %
    %       b = BATTERYPACK(__, 'OptionName', OptionValue)
    %           Used for specifying additional options, which are described below.
    %           The option names must be specified as strings.
    %
    %       BATTERYPACK.GUI starts a GUI for creating a BATTERYPACK object (requires JAVA).
    %
    %Input arguments:
    %
    %   Cp  -  Battery pack nominal capacity in Ah.
    %   Vp  -  Battery pack nominal voltage in V.
    %   Cc  -  Cell capacity (nominal) in Ah.
    %   Vc  -  Cell voltage (nominal) in V.
    %   np  -  Number of elements per parallel element (must be an
    %          integer if 'Setup' option is left out).
    %   ns  -  Number of elements per string (must be an
    %          integer if 'Setup' option is left out).
    %
    %
    %Additional Options:
    %
    %   'ageModel'                - 'none' (default), 'EO', or a custom age model object
    %                               that implements the batteryAgeModel interface.
    %                               -> 'EO' = event oriented aging model (eoAgeModel object)
    %
    %   'AgeModelLevel'           - 'Pack' (default) or 'Cell'
    %                             -> Specifies whether the age model is applied to the pack
    %                             or to each cell individually. Applying the age model to the
    %                             pack should result in faster simulation times.
    %
    %   'cycleCounter'            - 'auto' (default), 'dambrowski' or a custom cycle counter
    %                               object that implements the cycleCounter
    %                               interface. By default, no cycle counter is
    %                               implemented if 'ageModel' is set to 'none',
    %                               otherwise the 'dambrowski' counter is used.
    %
    %   'Equalization'            - 'Passive' (default) or 'Active'.
    %                             -> Specifies which type of equalization (balancing)
    %                             is used for the strings in the pack.
    %
    %   'etaBC'                   - default: 0.97
    %                             -> The battery pack's charging efficiency. If
    %                             the data sheets do not differentiate between
    %                             charging and discharging efficiency, set
    %                             'etaBC' to the given efficiency and set 'etaBD'
    %                             to 1.
    %
    %   'etaBD'                   - default: 0.97
    %                             -> The battery pack's discharging efficiency.
    %                             Set this to 1 if the data sheets do not
    %                             differentiate between charging and discharging
    %                             efficiencies.
    %
    %   'ideal'                   - true or false (default)
    %                             -> Set this to true to simulate a simpler
    %                             model with ideal cells and balancing. Setting
    %                             this to true assumes all cells have exactly
    %                             the same parameters and that the balancing is
    %                             perfect. This should result in much fewer
    %                             resources during simulation, as only one cell
    %                             is used for calculations.
    %
    %   'psd'                    - Self-discharge in 1/month [0,..,1] (default: 0)
    %                             -> i. e. 0.01 for 1 %/month
    %
    %   'socMax'                 - default: 1
    %                             -> Upper limit for the battery pack's state of
    %                             charge SoC.
    %
    %   'socMin'                 - default: 0.2
    %                             -> Lower limit for the battery pack's SoC.
    %                             Note that the SoC can go below this limit if
    %                             it is above 0 and if a self-discharge has
    %                             been specified.
    %
    %   'socIni'                 - default: 0.2
    %                             -> Initialial SoC of the battery pack.
    %
    %   'sohIni'                 - default: 1
    %                             -> Initial state of health SoH of the battery
    %                             pack and/or cells (depending on the
    %                             'AgeModelLevel')
    %
    %   'Topology'               - 'SP' (default) or 'PS'
    %                             -> The topology of the pack's circuitry. 'SP'
    %                             for strings of parallel cells and 'PS' for
    %                             parallel strings of cells.
    %
    %   'Zi'                     - default: 17e-3
    %                             -> Internal impedance of the cells in Ohm.
    %                             The internal impedance is currently not used
    %                             as a physical parameter. However, it is used
    %                             in the circuit elements to determine the
    %                             distribution of currents and voltages.
    %                                   
    %
    %   'Zgauss'                 - default: [0, Zi, Zi]
    %                            -> Vector for gaussian distribution of battery
    %                            cells' internal impedances. The vector has the
    %                            following values: [Zstd, Zmin, Zmax] with
    %                               Zstd = Standard deviation of Zi in Ohm
    %                               Zmin = Smallest Zi in Ohm
    %                               Zmax = Largest Zi in Ohm
    %                            The mean is the value specified by the option
    %                            'Zi'. This setting is ignored if the 'ideal'
    %                            option is set to true.
    %                            Notes: 
    %                                - In order to use this option, the Statistics
    %                                  and Machine Learning Toolbox is
    %                                  required.
    %                                - Due to the limitation using Zmin and Zmax, a
    %                                  the mean or std may vary slightly from what was
    %                                  set. To get an exact std and mean, Zmin must be
    %                                  set to -Inf and Zmax must be set to Inf.
    %
    %   'dCurves'                - default: 'none'
    %                            -> adds dischargeCurve object to the battery's
    %                            cells.
    %
    %   'ageCurve'               - default: 'none'
    %                            -> adds an age curve (e. g. a woehlerFit) to
    %                            the battery's cells.
    %
    %
    %Authors: Marc Jakobi, Festus Anynagbe, Marc Schmidt
    %         January 2017
    %
    %
    %SEE ALSO: lfpBattery.batCircuitElement lfpBattery.seriesElement
    %          lfpBattery.seriesElementPE lfpBattery.seriesElementAE
    %          lfpBattery.parallelElement lfpBattery.simplePE
    %          lfpBattery.simpleSE lfpBattery.batteryCell
    %          lfpBattery.batteryAgeModel lfpBattery.eoAgeModel
    %          lfpBattery.dambrowskiCounter lfpBattery.cycleCounter
    properties (SetAccess = 'protected')
        AgeModelLevel;
    end
    properties (Dependent)
        V; % Resting voltage of the battery pack in V
    end
    properties (Dependent, SetAccess = 'protected')
        % Internal impedance of the battery pack in Ohm.
        % The internal impedance is currently not used as a physical
        % parameter. However, it is used in the circuit elements
        % (seriesElement/parallelElement) to determine the distribution
        % of currents and voltages.
        Zi;
        % Discharge capacity in Ah (Cd = 0 if SoC = 1).
        % The discharge capacity is given by the nominal capacity Cn and
        % the current capacity C at SoC.
        % Cd = Cn - C
        Cd;
        % Current capacity level in Ah.
        C;
    end
    properties (SetAccess = 'protected')
       nP; % number of parallel elements
       nS; % number of elements in series
    end
    
    methods
        function b = batteryPack(Cp, Vp, Cc, Vc, varargin)
            %BATTERYPACK: Initializes a cell-resolved model of a lithium ion battery pack.
            %
            %Syntax:
            %       b = BATTERYPACK(Cp, Vp, Cc, Vc);
            %           Initializes a battery pack with the nominal cell voltae Vc and the
            %           nominal cell capacity Cc. The cells are arranged as strings of
            %           parallel cells in such a way that the pack's nominal voltage Vp
            %           and capacity Cp come as close as possible to the inputs Cp and Vp.
            %
            %       b = BATTERYPACK(np, ns, Cc, Vc);
            %           np and ns must be integers for this syntax, otherwise the above syntax
            %           is interpreted!
            %           Initializes a battery pack with the nominal cell voltae Vc and the
            %           nominal cell capacity Cc. The cells are arranged as ns strings of
            %           parallel elements with np parallel cells. The pack's nominal capacity
            %           depends on the cell voltage Vc and on the number of parallel cells np.
            %           The pack's nominal voltage depends on the cell voltage Vc and on the
            %           number of elements per string ns.
            %
            %       b = BATTERYPACK(np, ns, Cc, Vc, 'Setup', 'Manual');
            %           Initializes a battery pack with the nominal cell voltae Vc and the
            %           nominal cell capacity Cc. The cells are arranged as ns strings of
            %           parallel elements with np parallel cells. The pack's nominal capacity
            %           depends on the cell voltage Vc and on the number of parallel cells np.
            %           The pack's nominal voltage depends on the cell voltage Vc and on the
            %           number of elements per string ns.
            %           np and ns can be any numerical data type using this syntax.
            %
            %       b = BATTERYPACK(__, 'OptionName', OptionValue)
            %           Used for specifying additional options, which are described below.
            %           The option names must be specified as strings.
            %
            %       BATTERYPACK.GUI starts a GUI for creating a BATTERYPACK object.
            %
            %
            %Input arguments:
            %
            %   Cp  -  Battery pack nominal capacity in Ah.
            %   Vp  -  Battery pack nominal voltage in V.
            %   Cc  -  Cell capacity (nominal) in Ah.
            %   Vc  -  Cell voltage (nominal) in V.
            %   np  -  Number of elements per parallel element (must be an
            %          integer if 'Setup' option is left out).
            %   ns  -  Number of elements per string (must be an
            %          integer if 'Setup' option is left out).
            %
            %Additional Options:
            %
            %   'ageModel'                - 'none' (default), 'EO', or a custom age model object
            %                               that implements the batteryAgeModel interface.
            %                               -> 'EO' = event oriented aging model (eoAgeModel object)
            %
            %   'AgeModelLevel'           - 'Pack' (default) or 'Cell'
            %                             -> Specifies whether the age model is applied to the pack
            %                             or to each cell individually. Applying the age model to the
            %                             pack should result in faster simulation times.
            %
            %   'cycleCounter'            - 'auto' (default), 'dambrowski' or a custom cycle counter
            %                               object that implements the cycleCounter
            %                               interface. By default, no cycle counter is
            %                               implemented if 'ageModel' is set to 'none',
            %                               otherwise the 'dambrowski' counter is used.
            %
            %   'Equalization'            - 'Passive' (default) or 'Active'.
            %                             -> Specifies which type of equalization (balancing)
            %                             is used for the strings in the pack.
            %
            %   'etaBC'                   - default: 0.97
            %                             -> The battery pack's charging efficiency. If
            %                             the data sheets do not differentiate between
            %                             charging and discharging efficiency, set
            %                             'etaBC' to the given efficiency and set 'etaBD'
            %                             to 1.
            %
            %   'etaBD'                   - default: 0.97
            %                             -> The battery pack's discharging efficiency.
            %                             Set this to 1 if the data sheets do not
            %                             differentiate between charging and discharging
            %                             efficiencies.
            %
            %   'ideal'                   - true or false (default)
            %                             -> Set this to true to simulate a simpler
            %                             model with ideal cells and balancing. Setting
            %                             this to true assumes all cells have exactly
            %                             the same parameters and that the balancing is
            %                             perfect. This should result in much fewer
            %                             resources during simulation, as only one cell
            %                             is used for calculations.
            %
            %   'socMax'                 - default: 1
            %                             -> Upper limit for the battery pack's state of
            %                             charge SoC.
            %
            %   'socMin'                 - default: 0.2
            %                             -> Lower limit for the battery pack's SoC.
            %                             Note that the SoC can go below this limit if
            %                             it is above 0 and if a self-discharge has
            %                             been specified.
            %
            %   'socIni'                 - default: 0.2
            %                             -> Initialial SoC of the battery pack.
            %
            %   'sohIni'                 - default: 1
            %                             -> Initial state of health SoH of the battery
            %                             pack and/or cells (depending on the
            %                             'AgeModelLevel')
            %
            %   'Topology'               - 'SP' (default) or 'PS'
            %                             -> The topology of the pack's circuitry. 'SP'
            %                             for strings of parallel cells and 'PS' for
            %                             parallel strings of cells.
            %
            %   'Zi'                     - default: 17e-3
            %                             -> Internal impedance of the cells in Ohm.
            %                             The internal impedance is currently not used
            %                             as a physical parameter. However, it is used
            %                             in the circuit elements to determine the
            %                             distribution of currents and voltages.
            %
            %   'Zgauss'                 - default: [0, Zi, Zi]
            %                            -> Vector for gaussian distribution of battery
            %                            cells' internal impedances. The vector has the
            %                            following values: [Zstd, Zmin, Zmax] with
            %                               Zstd = Standard deviation of Zi in Ohm
            %                               Zmin = Smallest Zi in Ohm
            %                               Zmax = Largest Zi in Ohm
            %                            The mean is the value specified by the option
            %                            'Zi'. This setting is ignored if the 'ideal'
            %                            option is set to true.
            %                            Notes: - In order to use this option, the Statistics
            %                                     and Machine Learning Toolbox is required.
            %                                   - Due to the limitation using Zmin and Zmax, a
            %                                     the mean or std may vary slightly from what was
            %                                     set. To get an exact std and mean, Zmin must be
            %                                     set to -Inf and Zmax must be set to Inf.
            %
            %   'dCurves'                - default: 'none'
            %                            -> adds dischargeCurve object to the battery's
            %                            cells.
            %
            %   'ageCurve'               - default: 'none'
            %                            -> adds an age curve (e. g. a woehlerFit) to
            %                            the battery's cells.
            import lfpBattery.*
            p = batteryInterface.bInputParser; % load default optargs
            % add additional optargs to parser
            valid = {'Pack', 'Cell'};
            addOptional(p, 'AgeModelLevel', 'Pack', @(x) any(validatestring(x, valid)))
            valid = {'SP', 'PS'}; % strings of parallel elements / parallel strings
            addOptional(p, 'Topology', 'SP', @(x) any(validatestring(x, valid)))
            valid = {'Passive', 'Active'};
            addOptional(p, 'Equalization', 'Passive', @(x) any(validatestring(x, valid)))
            valid = {'Auto', 'Manual'};
            addOptional(p, 'Setup', 'Auto', @(x) any(validatestring(x, valid)))
            addOptional(p, 'ideal', false, @islogical)
            addOptional(p, 'Zgauss', [0 0 0], @(x) isnumeric(x) & numel(x) == 3)
            addOptional(p, 'dCurves', 'none', @(x) batteryPack.validateCurveOpt(x,...
                'lfpBattery.curvefitCollection'))
            addOptional(p, 'ageCurve', 'none', @(x) batteryPack.validateCurveOpt(x,...
                'lfpBattery.curveFitInterface'))
            % parse inputs
            parse(p, varargin{:})
            % prepare age model and cycle counter params at pack/cell levels
            amL = p.Results.AgeModelLevel;
            am = p.Results.ageModel;
            cy = p.Results.cycleCounter;
            if strcmpi(amL, 'Cell') % age model level: cell
                if ~strcmpi(am, 'none') % age model specified
                    cellAm = am; % cell age model arg
                    packAm = 'LowerLevel'; % pack age model arg
                    cellCy = cy; % cell cycle counter arg
                    packCy = 'auto'; % pack cycle counter arg
                else % no age model
                    cellAm = am;
                    packAm = am;
                    cellCy = 'auto';
                    packCy = 'auto';
                end
            else % age model level: Pack
                cellAm = 'none';
                packAm = am;
                cellCy = 'auto';
                packCy = cy;
            end
            % Extract optional arguments
            sohIni = p.Results.sohIni;
            socIni = p.Results.socIni;
            socMin = p.Results.socMin;
            socMax = p.Results.socMax;
            etaBC = p.Results.etaBD;
            etaBD = p.Results.etaBD;
            psd = p.Results.psd;
            % These arguments are used by every sub-element (cells, circuit
            % elements, etc.)
            commonArgs = {'sohIni', sohIni, 'socIni', socIni,...
                'socMin', socMin, 'socMax', socMax, 'etaBC', etaBC, 'etaBD', etaBD, 'psd', psd};
            % Initialize common arguments using superclass constructor
            b@lfpBattery.batteryInterface('ageModel', packAm, 'cycleCounter', packCy, ...
                commonArgs{:});
            if strcmpi(am, 'none') % correct age model level
                b.AgeModelLevel = 'no age model';
            else
                b.AgeModelLevel = amL; % set AgeModelLevel property
            end
            % Extract optional arguments and convert string arguments to logicals
            sp = strcmpi(p.Results.Topology, 'SP'); % SP (strings of parallel elements) or PS (parallel strings of cells)
            pe = strcmpi(p.Results.Equalization, 'Passive'); % passive or active equalization
            im = p.Results.ideal; % simplified, ideal model?
            Zi = p.Results.Zi; % internal impedance (mean if gauss)
            Zgauss = p.Results.Zgauss; % Gaussian distribution of internal impedances
            dC = p.Results.dCurves; % discharge curves ('none' by default)
            aC = p.Results.ageCurve; % cycle life furve ('none' by default)
            if isinteger(Cp) && isinteger(Vp) || strcmpi(p.Results.Setup, 'Manual') % automatic setup?
                % user-defined setup
                np = uint32(Cp);
                ns = uint32(Vp);
            else 
                % Estimate necessary config to get as close as possible to
                % desired nominal capacity and desired nominal voltage
                np = uint32(Cp ./ Cc); % number of parallel elements
                ns = uint32(Vp ./ Vc); % number of series elements
            end
            % Initialize circuitry
            % These arguments are used for the batteryCell objects
            cellArgs = [commonArgs, {'ageModel', cellAm, 'cycleCounter', cellCy, 'Zi', p.Results.Zi}];
            if im % simplified, ideal model
                if sp % strings of parallel elements
                    b.addElements(simpleSE(simplePE(batteryCell(Cc, Vc, cellArgs{:}), np), ns));
                else % parallel strings of cells
                    b.addElements(simplePE(simpleSE(batteryCel(Cc, Vc, cellArgs{:}), ns), np));
                end
            else % non-simplified model
                if Zgauss(1) ~= 0 % Gaussian distribution of internal impedances?
                    try 
                        % Get approx. gaussian distribution within limited
                        % interval.
                        Zi = commons.norminvlim(rand(np.*ns, 1), Zi, Zgauss(1), Zgauss(2:3));
                    catch ME
                        if ~license('test', 'statistics_toolbox') % statistics toolbox missing?
                            error('The Statistics toolbox is required in order to set a gaussian distribution for Zi.')
                        else
                            rethrow(ME) % otherwise rethrow exception
                        end
                    end
                else % No Gaussian distribution
                    Zi = repmat(Zi, np.*ns, 1);
                end
                % Define function handles pointing to wrapper objects
                % (composite decorators), depending on the topology and
                % equalization
                if sp % strings of parallel elements
                    outer = @parallelElement; % function handle for outer wrapper
                    outerN = np; % number of elements outer wrapper holds
                    innerN = ns; % number of cells each inner wrapper holds
                    if pe % passive equalization
                        inner = @seriesElementPE; % inner wrappers
                    else % active equalization
                        inner = @seriesElementAE;
                    end
                else % parallel strings of cells
                    inner = @parallelElement;
                    innerN = np;
                    outerN = ns;
                    if pe % passive equalization
                        outer = @seriesElementPE;
                    else % active equalization
                        outer = @seriesElementAE;
                    end
                end
                % Set up circuitry using function handles of wrappers
                eo = outer(commonArgs{:}); % outer element
                ct = uint32(0); % counter
                for j = uint32(1):outerN
                    ei = inner(commonArgs{:}); % inner elements
                    for i = uint32(1):innerN % initiate cells
                        ct = ct + 1;
                        cellArgs{end} = Zi(ct);
                        cell = batteryCell(Cc, Vc, cellArgs{:}); % cells
                        ei.addElements(cell) % add cells to inner wrappers
                    end
                    eo.addElements(ei) % wrap inner wrappers with outer wrapper
                end
                b.addElements(eo); % add outer wrapper to battery pack
            end
            b.refreshNominals; % Retrieve nominal voltage and capacity from topology.
            % pass curve fits
            if strcmpi(dC, 'none') % warn if no discharge curves specified (default)
                warning(['Battery pack initialized without discharge curve fits. ', ...
                    'Add curve fits to the model using this class''s addcurves() method. ', ...
                    'Attempting to use this model without discharge curve fits will result in an error.'])
            else % If discharge curves were specified, add them to the battery cells.
                b.addcurves(dC)
            end
            % Do the same for age model curves if an age model was
            % specified.
            if strcmpi(aC, 'none') && ~strcmpi(am, 'none')
                warning(['Battery pack initialized without cycle life curve fits although an age model was specified. ', ...
                    'Add curve fits to the model using this class''s addcurves() method. ', ...
                    'Attempting to use this model without cycle life curve fits will result in an error.'])
            elseif ~strcmpi(aC, 'none')
                b.addcurves(aC, 'cycleLife')
            end
        end % constructor
        function addcurves(b, d, type)
            if nargin < 3
                type = 'discharge';
            end
            if strcmpi(type, 'cycleLife') && strcmpi(b.AgeModelLevel, 'Pack')
                if ~strcmpi(b.AgeModelLevel, 'no age model')
                    b.ageModel.wFit = d;
                else
                    error('No age model specified this battery pack.')
                end
            else
                % pass curve to all cells if discharge curve or cycle life
                % curve and age model level is 'Pack'
                b.pass2cells(@addcurves, d, type);
            end
            b.findImaxD;
        end
        function addElements(b, e)
            % ADDELEMENTS: Adds elements to the batteryPack. An element can
            % be a batteryCell, a parallelElement, a stringElementAE, a
            % stringElementPE, a simplePE, a simpleSE or a user-defined 
            % element that implements the batteryInterface.
            %
            % Syntax: b.ADDELEMENTS(e)
            %         ADDELEMENTS(e) % has the same effect
            %
            % Input arguments:
            %   b        - The batteryPack the elements are added to.
            %   e        - The element being added to the collection.
            %
            % Using this method to add an element to a batteryPack will replace the current
            %   element held by the batteryPack.
            lfpBattery.commons.validateInterface(e, 'lfpBattery.batteryInterface')
            if isa(e, 'lfpBattery.batteryPack')
                error('batteryPack objects cannot be added to batteryPack objects.')
            end
            if ~e.hasCells
                error('Attempted to add element that does not contain any cells.')
            end
            [b.nP, b.nS] = e.getTopology;
            b.El = e;
            b.nEl = uint32(1);
        end
        function v = getNewVoltage(b, I, dt)
            v = b.El.getNewVoltage(I, dt);
        end
        function [np, ns] = getTopology(b)
            [np, ns] = b.El.getTopology;
        end
        function charge(b, Q)
            b.El.charge(Q)
        end
        function c = dummyCharge(b, Q)
            c = b.El.dummyCharge(Q);
        end
        function i = findImaxD(b)
            i = b.El.findImaxD;
            b.Imax = i;
        end
        %% getters & setters
        function set.V(b, v)
            b.El.V = deal(v);
        end
        function v = get.V(b)
            v = b.El.V;
        end
        function c = get.Cd(b)
            c = b.El.Cd;
        end
        function c = get.C(b)
            c = b.El.C;
        end
        function z = get.Zi(b)
            z = b.El.Zi;
        end
    end
    
    methods (Access = 'protected')
        function pass2cells(b, fun, varargin)
            %PASS2CELLS: Passes the function specified by function handle fun
            %to all cells in this pack
            it = b.El.createIterator;
            while it.hasNext
                cell = it.next;
                feval(fun, cell, varargin{:});
            end
        end
        % Abstract methods passed on to El handle
        function refreshNominals(b)
            b.Vn = b.El.Vn;
            b.Cn = b.El.Cn;
        end
        function s = sohCalc(b)
            s = b.El.SoH;
        end
    end
    
    methods (Static)
        function digitizeTool
            % DIGITIZETOOL: Opens a GUI for digitizing discharge curves and
            % cycle life curves.
            lfpBattery.digitizeTool;
        end
        function GUI
            % GUI: Opens a GUI for creating a batteryPack model.
            lfpBattery.bpackGUI;
        end
    end
    
%     methods (Access = 'protected')
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
%     end
    
    methods (Static, Access = 'protected')
        function validateCurveOpt(x, validInterface)
            if ~strcmpi(x, 'none')
                lfpBattery.commons.validateInterface(x, validInterface)
            end
        end
    end
end 