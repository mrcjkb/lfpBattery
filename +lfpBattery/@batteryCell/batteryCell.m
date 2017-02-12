classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Li-ion battery cell model based on fitted discharge curves.
    %
    % Syntax:   b = BATTERYCELL(Cn, Vn);
    %           b = BATTERYCELL(Cn, Vn, 'OptionName', OptionValue);
    %
    % Input arguments:
    % Cn            -    Nominal capacity in Ah (default: empty)
    % Vn            -    Nominal voltage in Ah (default: empty)
    %
    % Name-Value pairs:
    %
    % 'Zi'            -    Internal impedance in Ohm (default: 17e-3)
    % 'sohIni'        -    Initial state of health [0,..,1] (default: 1)
    % 'socIni'        -    Initial state of charge [0,..,1] (default: 0.2)
    % 'socMin'        -    Minimum state of charge (default: 0.2)
    % 'socMax'        -    Maximum state of charge (default: 1)
    % 'psd'           -    Self-discharge in 1/month [0,..,1] (default: 0)
    % 'ageModel'      -    'none' (default), 'EO' (for event oriented
    %                      aging) or a custom age model that implements
    %                      the batteryAgeModel interface.
    % 'cycleCounter'  -    'auto' for automatic determination
    %                      depending on the ageModel (none for 'none'
    %                      and dambrowskiCounter for 'EO' or a custom
    %                      cycle counter that implements the
    %                      cycleCounter interface.
    %
    % BATTERYCELL Methods:
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
    % randomizedc       - Re-fits the discharge curve with a slight
    %                     randomization of the initial x parameters.
    %
    %
    % BATTERYCELL Properties:
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
    % maxIterations     - Maximum number of iterations in iteratePower()
    %                     and iterateCurrent() methods.
    % pTol              - Tolerance for the power iteration in W.
    % sTol              - Tolerance for SoC limitation iteration.
    %
    %SEE ALSO: lfpBattery.batteryPack
    %          lfpBattery.batCircuitElement lfpBattery.seriesElement
    %          lfpBattery.seriesElementPE lfpBattery.seriesElementAE
    %          lfpBattery.parallelElement lfpBattery.simplePE
    %          lfpBattery.simpleSE
    %
    %Authors: Marc Jakobi, Festus Anynagbe, Marc Schmidt
    %         January 2017
    
    properties (Hidden, Access = 'protected');
        dC; % curvefitCollection (dischargeCurves object)
        cC; % cccvFit (constant current, constant voltage curve fit)
        Vi; % for storing dependent V property
        zi; % for storing dependent Zi property
        socCV = inf; % state of charge at which the CV phase begins
        cvFlag = false; % flag that indicates wheter cell is in CV phase of charging
    end
    properties (Dependent)
        V; % Resting voltage / V
    end
    properties (Dependent, SetAccess = 'protected')
        % Internal impedance in Ohm.
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
    
    events
        % Indicates that the batteryPack BMS needs to re-calculate the maximum current
        % for the constant voltage phase of charging
        CV;
        % Indicates that the batteryPack BMS needs to re-calculate the maximum current
        % for the constant current phase of charging
        CC;
    end
    
    methods
        function b = batteryCell(Cn, Vn, varargin)
            % BATTERYCELL: Initializes a BATTERYCELL object. 
            %
            % Syntax:   b = BATTERYCELL(Cn, Vn);
            %           b = BATTERYCELL(Cn, Vn, 'OptionName', 'OptionValue');
            %
            % Input arguments:
            % Cn            -    nominal capacity in Ah (default: empty)
            % Vn            -    nominal voltage in Ah (default: empty)
            %
            % Name-Value pairs:
            %
            % Zi            -    internal impedance in Ohm (default: 17e-3)
            % sohIni        -    initial state of health [0,..,1] (default: 1)
            % socIni        -    initial state of charge [0,..,1] (default: 0.2)
            % socMin        -    minimum state of charge (default: 0.2)
            % socMax        -    maximum state of charge (default: 1)
            % ageModel      -    'none' (default), 'EO' (for event oriented
            %                    aging) or a custom age model that implements
            %                    the batteryAgeModel interface.
            % cycleCounter  -    'auto' for automatic determination
            %                    depending on the ageModel (none for 'none'
            %                    and dambrowskiCounter for 'EO' or a custom
            %                    cycle counter that implements the
            %                    cycleCounter interface.
            b@lfpBattery.batteryInterface(varargin{:})
            % parse optional inputs
            p = lfpBattery.batteryInterface.parseInputs(varargin{:});
            b.Zi = p.Results.Zi;
            b.Cn = Cn;
            b.Cdi = (1 - b.soc) * b.Cn;
            b.Vn = Vn;
            b.V = b.Vn;
            b.hasCells = true; % always true for batteryCell
            b.isCell = true; % always false for batteryCell
        end % constructor
        function [v, cd] = getNewVoltage(b, I, dt)
            cd = b.Cd - I * dt * b.secsToHours;
            v = b.dC.interp(I, cd);
        end
        function it = createIterator(b)
            it = lfpBattery.nullIterator(b);
        end
        function [np, ns] = getTopology(b) %#ok<MANU>
            np = uint32(1);
            ns = uint32(1);
        end
        function randomizeDC(b)
            % RANDOMIZEDC: Re-fits the discharge curve fits by
            % creating deep copies, re-initializing the x parameters with
            % random integers and replacing the curve fit collection of
            % this battery cell with the re-fitted deep copy.
            dc = copy(b.dC); % deep copy discharge curve collection
            it = dc.createIterator;
            while it.hasNext
                dF = it.next; % individual curve fits
                df = copy(dF); % create deep copy
                df.x = randi(100, df.getnumXparams, 1); % reset fit by randomizing output
                dc.add(df); % re-add to collection
            end
            b.dC = dc;
        end
        function charge(b, Q)
            b.Cdi = b.Cdi - Q;
            b.refreshSoC;
            if b.SoC > b.socCV % Constant voltage phase?
                b.clBMS = true; % set clBMS flag on cell level in case single cell is being simulated
                b.cvFlag = true; % set flag to indicate cell is in constant voltage phase
                % Notify Battery pack that BMS needs to activate charge
                % limiting for next time step
                notify(b, 'CV')
            elseif b.cvFlag && b.SoC <= b.socCV % Exiting constant voltage phase through discharge?
                b.clBMS = true;
                b.cvFlag = false;
                notify(b, 'CC')
            end
        end
        function c = dummyCharge(b, Q)
            c = b.C + Q;
        end
        %% Methods handled by strategy objects
        function addcurves(b, d, type)
            if nargin < 3
                type = 'discharge';
            end
            if strcmp(type, 'discharge')
                if isempty(b.dC) % initialize dC property with d
                    if lfpBattery.commons.itfcmp(d, 'lfpBattery.curvefitCollection')
                        b.dC = d; % init with collection
                    else
                        b.dC = lfpBattery.dischargeCurves; % create new curve fit collection
                        b.dC.add(d)
                    end
                else % add d if dC exists already
                    b.dC.add(d)
                end
            elseif strcmp(type, 'cycleLife')
                b.ageModel.wFit = d; % MTODO: Implement tests for this
            elseif strcmp(type, 'charge')
                b.cC = d;
                b.socCV = d.soc0; % SoC threshold for charge limiting
                if b.SoC > b.socCV
                    b.clBMS = true; % charge limiting BMS flag
                end
            end
            b.findImaxD;
            b.findImaxC;
        end
        function i = findImaxD(b)
            d = [b.dC];
            nB = numel(b);
            if numel(d) == nB
                i = max([d.z]);
            else
                if isempty(d)
                    i = zeros(1, numel(b));
                else
                    i = [max([d.z]), zeros(1, nB - numel(d))];
                end
            end
            for ind = 1:nB
                b(ind).ImaxD = i(ind);
            end
        end
        function i = findImaxC(b)
            d = [b.cC];
            nB = numel(b);
            if numel(d) == nB
                i = d([b.SoC]);
            else
                if isempty(d)
                    i = zeros(1, nB - numel(d));
                else
                    i = [d([b.SoC]), zeros(1, nB - numel(d))];
                end
            end
            for ind = 1:nB
                b(ind).ImaxC = i(ind);
            end        
        end
        %% Getters & setters
        function v = get.V(b)
            v = b.Vi;
        end
        function set.V(b, v)
            b.Vi = v;
        end
        function c = get.Cd(b)
            c = b.Cdi;
        end
        function c = get.C(b)
            c = b.Cn - b.Cdi;
        end
        function set.Zi(b, z)
            b.zi = z;
        end
        function z = get.Zi(b)
            z = b.zi;
        end
    end
    
    methods (Access = 'protected')
        function refreshNominals(b)   %#ok<MANU> Method not needed
            warning('refreshNominals() should not be called on a batteryCell.')
        end
        function s = sohCalc(b)
            % sohCalc always points to internal soh for batteryCell
            s = b.soh;
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
end

