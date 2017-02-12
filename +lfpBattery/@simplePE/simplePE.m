classdef simplePE < lfpBattery.simpleCircuitElement
    % SIMPLEPE Simplified implementation of the parallelElement. This
    % version assumes That all battery cells are exactly the same for
    % the purpose of shorter simulation times. This class can be used as a
    % decorator for the simpleSE, other simplePE and batteryCell objects.
    %
    %
    % Syntax: b = SIMPLEPE(bObj, n);
    %
    %
    % Input arguments:
    % bObj        - Battery object that is being wrapped (Can be a
    %               batteryCell, a simpleSE, another SIMPLEPE or a custom
    %               class that implements the batCircuitElement
    %               interface.
    % n           - Number of elements ("copies" of bObj) in the circuit element b.
    %
    %
    % SIMPLEPE Methods:
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
    % getTopology       - Returns the number of parallel elements np and the
    %                     number of elements in series ns in a battery object b.
    % randomizeDC       - Slight randomization of the cell's discharge
    %                     curve fits.
    %
    %
    % SIMPLEPE Properties:
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
    %SEE ALSO: lfpBattery.batteryPack lfpBattery.batteryCell
    %          lfpBattery.batCircuitElement lfpBattery.seriesElement
    %          lfpBattery.seriesElementAE lfpBattery.parallelElement
    %          lfpBattery.seriesElementsPE lfpBattery.simpleSE
    %
    %Authors: Marc Jakobi, Festus Anynagbe, Marc Schmidt
    %         January 2017
    
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
    
    methods
        function b = simplePE(obj, n)
            % SIMPLEPE Simplified implementation of the parallelElement. This
            % version assumes That all battery cells are exactly the same for
            % the purpose of shorter simulation times. This class can be used as a
            % decorator for the simpleSE, other simplePE and batteryCell objects.
            %
            %
            % Syntax: b = SIMPLEPE(bObj, n);
            %
            %
            % Input arguments:
            % bObj        - Battery object that is being wrapped (Can be a
            %               batteryCell, a simpleSE, another SIMPLEPE or a custom
            %               class that implements the batCircuitElement
            %               interface.
            % n           - Number of elements ("copies" of bObj) in the circuit element b.
            if ~obj.hasCells
                error('Object being wrapped does not contain any cells.')
            end
            b@lfpBattery.simpleCircuitElement(obj); % superclass constructor
            b.El = obj;
            b.nEl = double(n);
            b.findImaxD;
            b.refreshNominals;
            b.hasCells = true;
        end
        function v = getNewVoltage(b, I, dt)
            % split I equally across elements
            v = b.El.getNewVoltage(I / b.rnEl, dt);
        end
        function [np, ns] = getTopology(b)
            [np, ns] = b.El.getTopology;
            np = b.nEl * np;
        end
        function charge(b, Q)
            % Pass equal amount of discharge capacity to each element
            % to account for self-balancing nature of parallel config
            b.El.charge(1 / b.nEl * Q);
        end
        function c = dummyCharge(b, Q)
            c = b.nEl * b.El.dummyCharge(Q / b.nEl);
        end
        function addElements(varargin)
            error('addElements is not supported for simplePE objects. The element is passed in the constructor.')
        end
        function i = findImaxD(b)
            i = b.nEl * b.El.findImaxD;
            b.ImaxD = i;
        end
        function i = findImaxC(b)
            i = b.nEl * b.El.findImaxC;
            b.ImaxC = i;
        end
        %% Setters & getters
        function set.V(b, v)
            % Pass v down
            b.El.V = v;
        end
        function v = get.V(b)
            v = b.El.V; % Voltage is the same across all elements
        end
        function c = get.Cd(b)
            c = b.nEl * b.El.Cd;
        end
        function c = get.C(b)
            c = b.nEl * b.El.C;
        end
        function z = get.Zi(b)
            z = 1 / (b.nEl / b.El.Zi); % 1/z_total = sum_i(1/z_i)
        end
    end
    
    methods (Access = 'protected')
        function p = getZProportions(b)
            p = ones(b.nEl, 1) / b.nEl;
        end
        function refreshNominals(b)
            b.Vn = b.El.Vn;
            b.Cn = b.nEl * b.El.Cn;
        end 
        function s = sohCalc(b)
            s = b.El.SoH;
        end
        % gpuCompatible methods
        function setsubProp(obj, fn, val)
            obj.(fn) = val;
        end
        function val = getsubProp(obj, fn)
            val = obj.(fn);
        end
    end
end

