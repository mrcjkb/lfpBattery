classdef batteryCell < lfpBattery.batteryInterface
    %BATTERYCELL: Li-ion battery cell model based on fitted discharge curves.
    %
    % Syntax:   b = BATTERYCELL(Cn, Vn);
    %           b = BATTERYCELL(Cn, Vn, 'OptionName', 'OptionValue');
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
    % iTol              - Tolerance for current limitation iteration in A.
    %
    %SEE ALSO: lfpBattery.batteryPack
    %          lfpBattery.batCircuitElement lfpBattery.seriesElement
    %          lfpBattery.seriesElementPE lfpBattery.seriesElementAE
    %          lfpBattery.parallelElement lfpBattery.simplePE
    %          lfpBattery.simpleSE
    %
    %Authors: Marc Jakobi, Festus Anynagbe, Marc Schmidt
    %         January 2017
    
    properties (Access = 'protected');
        dC; % curvefitCollection (dischargeCurves object)
        Vi; % for storing dependent V property
        zi; % for storing dependent Zi property
    end
    properties (Dependent)
        V; % Resting voltage / V
    end
    properties (Dependent, SetAccess = 'protected')
        % Discharge capacity in Ah (Cd = 0 if SoC = 1).
        % The discharge capacity is given by the nominal capacity Cn and
        % the current capacity C at SoC.
        % Cd = Cn - C
        Cd;
        % Current capacity level in Ah.
        C;
    end
    properties (Dependent, SetAccess = 'immutable')
        % Internal impedance in Ohm.
        % The internal impedance is currently not used as a physical
        % parameter. However, it is used in the circuit elements
        % (seriesElement/parallelElement) to determine the distribution
        % of currents and voltages.
        Zi;
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
            b.Cdi = (1 - b.soc) .* b.Cn;
            b.Vn = Vn;
            b.V = b.Vn;
            b.hasCells = true; % always true for batteryCell
        end % constructor
        function [v, cd] = getNewVoltage(b, I, dt)
            cd = b.Cd - I .* dt ./ 3600;
            v = b.dC.interp(I, cd);
        end
        function it = createIterator(~)
            it = lfpBattery.nullIterator;
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
            end
            b.findImax();
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
            c = b.Cn - b.Cd;
        end
        function set.Zi(b, z)
            b.zi = z;
        end
        function z = get.Zi(b)
            z = b.zi;
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            if ~isempty(b.dC)
                b.Imax = max(b.dC.z);
            else
                b.Imax = 0;
            end
            if nargout > 0
                i = b.Imax;
            end
        end
        function refreshNominals(b)   %#ok<MANU> Method not needed
            warning('refreshNominals() should not be called on a batteryCell.')
        end
        function charge(b, Q)
            b.Cdi = b.Cdi - Q;
            b.refreshSoC;
        end
        function c = dummyCharge(b, Q)
            c = b.C + Q;
        end
        function s = sohCalc(b)
            % sohCalc always points to internal soh for batteryCell
            s = b.soh;
        end
    end
end

