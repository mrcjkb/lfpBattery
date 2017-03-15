classdef simpleSE < lfpBattery.simpleCircuitElement
    % SIMPLESE Simplified implementation of the seriesElement.
    % (There is no differentiation between active and passive equalization 
    % in this simplified model. This version assumes That all battery cells
    % are exactly the same for the purpose of shorter simulation times. 
    % This class can be used as a decorator for the simplePE, other simpleSE
    % and batteryCell objects.
    %
    %
    % Syntax: b = SIMPLESE(bObj, n);
    %
    %
    % Input arguments:
    % bObj        - Battery object that is being wrapped (Can be a
    %               batteryCell, a simplePE, another SIMPLESE or a custom
    %               class that implements the batCircuitElement
    %               interface.
    % n           - Number of elements ("copies" of bObj) in the circuit element b.
    %
    %
    % SIMPLESE Methods:
    % powerRequest               - Requests a power in W (positive for charging, 
    %                              negative for discharging) from the battery.
    % iteratePower               - Iteration to determine new state given a certain power.
    % currentRequest             - Requests a current in A (positive for charging,
    %                              negative for discharging) from the battery.
    % iterateCurrent             - Iteration to determine new state given a certain current.
    % addCounter                 - Registers a cycleCounter object as an observer.
    % dischargeFit               - Uses Levenberg-Marquardt algorithm to fit a
    %                              discharge curve.
    % chargeFit                  - Uses Levenberg-Marquardt algorithm to
    %                              fit a charge curve.
    % cycleFit                   - Creates a fit object for a cycles to
    %                              failure vs. DoD curve and adds it to the pack.
    % cccvFit                    - Adds a CCCV curve fit to the pack.
    % initAgeModel               - Initializes the age model of the battery.
    % getNewDischargeVoltage     - Returns the new voltage according to a discharging current and a
    %                              time step size.
    % getNewChargeVoltage        - Returns the new voltage according to a charging current and a
    %                              time step size.
    % addcurves                  - Adds a collection of discharge/charge curves, a cycle
    %                              life curve or a CCCV curve to the battery.
    % getTopology                - Returns the number of parallel elements np and the
    %                              number of elements in series ns in a battery object b.
    %
    %
    % SIMPLESE Properties:
    % C                 - Current capacity level in Ah.
    % Cbu               - Useable capacity in Ah.
    % Cd                - Discharge capacity in Ah (Cd = 0 if SoC = 1).
    % Cn                - Nominal (or average) capacity in Ah.
    % eta_bc            - Efficiency when charging [0,..,1].
    % eta_bd            - Efficiency when discharging [0,..,1].
    % ImaxC             - Maximum charging current in A.
    % ImaxD             - Maximum discharging current in A.
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
        function b = simpleSE(obj, n)
            % SIMPLESE Simplified implementation of the seriesElement.
            % (There is no differentiation between active and passive equalization
            % in this simplified model. This version assumes That all battery cells
            % are exactly the same for the purpose of shorter simulation times.
            % This class can be used as a decorator for the simplePE, other simpleSE
            % and batteryCell objects.
            %
            %
            % Syntax: b = SIMPLESE(bObj, n);
            %
            %
            % Input arguments:
            % bObj        - Battery object that is being wrapped (Can be a
            %               batteryCell, a simplePE, another SIMPLESE or a custom
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
            b.findImaxC;
            b.refreshNominals;
            b.hasCells = true;
        end
        function v = getNewDischargeVoltage(b, I, dt)
            v = b.nEl * b.El.getNewDischargeVoltage(I, dt); % Voltage = number of elements times elements' voltage
        end
        function v = getNewChargeVoltage(b, I, dt)
            v = b.nEl * b.El.getNewChargeVoltage(I, dt); % Voltage = number of elements times elements' voltage
        end
        function [np, ns] = getTopology(b)
            [np, ns] = b.El.getTopology;
            ns = b.nEl * ns;
        end
        function charge(b, Q)
            % Pass equal amount of discharge capacity to each element
            b.El.charge(1 / b.nEl * Q);
        end
        function c = dummyCharge(b, Q)
            c = b.El.dummyCharge(Q);
        end
        function addElements(varargin)
            error('addElements is not supported for simpleSE objects. The element is passed in the constructor.')
        end
        function i = findImaxD(b)
            i = b.El.findImaxD;
            b.ImaxD = i;
        end
        function i = findImaxC(b)
            i = b.El.findImaxC;
            b.ImaxC = i;
        end
        %% Getters & setters
        function v = get.V(b)
            v = b.nEl * b.El.V;
        end
        function set.V(b, v)
            % share voltages evenly across elements
            b.El.V = v / b.nEl;
        end
        function z = get.Zi(b)
            z = b.nEl * b.El.Zi;
        end
        function c = get.Cd(b)
            c = b.El.Cd;
        end
        function c = get.C(b)
            c = b.El.C;
        end
    end
    
    methods (Access = 'protected')
        function p = getZProportions(b)
            p = ones(b.nEl, 1) / b.nEl;
        end
        function s = sohCalc(b)
            s = b.El.SoH;
        end
        function refreshNominals(b)
            b.Vn = b.nEl * b.El.Vn;
            b.Cn = b.El.Cn;
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

