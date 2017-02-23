classdef parallelElement < lfpBattery.batCircuitElement
    %PARALLELELEMENT: Composite/decorator (wrapper) for batteryCells and other
    %composite decorators that implement the batCircuitElement interface.
    %Used to create a parallel circuitry of cells or strings or a
    %combination.
    %
    % Syntax:   b = PARALLELELEMENT;
    %           b = PARALLELELEMENT('OptionName', 'OptionValue');
    %
    % Elements can be added to a PARALLELELEMENT object using it's
    % addElements() method. For example, adding n batteryCell objects will
    % create a parallel element of cells. Adding n stringElement objects
    % will create a circuit of parallel strings. Adding a parallelElement
    % to a stringElement will create a string of parallel elements circuit.
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
    % PARALLELELEMENT Methods:
    % powerRequest               - Requests a power in W (positive for charging, 
    %                              negative for discharging) from the battery.
    % iteratePower               - Iteration to determine new state given a certain power.
    % currentRequest             - Requests a current in A (positive for charging,
    %                              negative for discharging) from the battery.
    % iterateCurrent             - Iteration to determine new state given a certain current.
    % addCounter                 - Registers a cycleCounter object as an observer.
    % dischargeFit               - Uses Levenberg-Marquardt algorithm to fit a
    %                              discharge curve.
    % initAgeModel               - Initializes the age model of the battery.
    % getNewDischargeVoltage     - Returns the new voltage according to a discharging current and a
    %                              time step size.
    % getNewChargeVoltage        - Returns the new voltage according to a charging current and a
    %                              time step size.
    % addcurves                  - Adds a collection of discharge/charge curves, a cycle
    %                              life curve or a CCCV curve to the battery.
    % getTopology                - Returns the number of parallel elements np and the
    %                              number of elements in series ns in a battery object b.
    % randomizeDC                - Slight randomization of each cell's discharge
    %                              curve fits.
    %
    %
    % PARALLELELEMENT Properties:
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
    %          lfpBattery.seriesElementPE lfpBattery.seriesElementAE
    %          lfpBattery.simplePE lfpBattery.simpleSE
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
    properties  (Hidden, Access = 'protected')
        ecache = cell(3,1);
    end
    
    methods
        function b = parallelElement(varargin)
            b@lfpBattery.batCircuitElement(varargin{:})
        end
        function v = getNewDischargeVoltage(b, I, dt)
            p = b.getZProportions; % split I across elements according to their internal
                                   % impedance
            v = 0;
            for i = uint32(1):b.nEl
                v = v + b.El(i).getNewDischargeVoltage(I * p(i), dt);
            end
            v = v * b.rnEl;
        end
        function v = getNewChargeVoltage(b, I, dt)
            p = b.getZProportions; % split I across elements according to their internal
                                   % impedance
            v = 0;
            for i = uint32(1):b.nEl
                v = v + b.El(i).getNewChargeVoltage(I * p(i), dt);
            end
            v = v * b.rnEl;
        end
        function set.V(b, v)
            % Pass v on to all elements to account for self-balancing
            % nature of parallel config
            [b.El.V] = deal(v);
        end
        function v = get.V(b)
            v = sum([b.El.V]) * b.rnEl;
        end
        function c = get.Cd(b)
            c = sum([b.El.Cd]);
        end
        function c = get.C(b)
            c = sum([b.El.C]);
        end
        function z = get.Zi(b)
            if isempty(b.ecache{1})
                b.ecache{1} = 1 / sum((1 ./ [b.El.Zi])); % 1/z_total = sum_i(1/z_i)
            end
            z = b.ecache{1};
        end
        function [np, ns] = getTopology(b)
            [np, ns] = arrayfun(@(x) getTopology(x), b.El);
            np = max(b.nEl * np);
            ns = max(ns);
        end
        function charge(b, Q)
            % Simulate self-balancing nature of parallel config
            q = b.getZProportions * Q; % Spread charge according to internal impedances
            if isempty(b.ecache{2})
                b.ecache{2} = any(q ~= q(1));
            end
            if  b.ecache{2} % Is there a difference in the impedances?
                % simulate self-balancing of charge with intermediate SoC
                % variations
                b.chargeLoop(q) % charge sub-elements
                c = [b.El.C]; % resulting capacities
                % balancing: q = charge required for each cell to reach mean
                % SoC
                q = sum(c) * b.rnEl - c; % mean
                b.chargeLoop(q) % charge cells
            else
                % simpler self-balancing (pass equal amount of charge to
                % each cell --> no intermediate SoC variations)
                charge@lfpBattery.batCircuitElement(b, Q * b.rnEl)
            end
        end
        function c = dummyCharge(b, Q)
            c = sum(dummyCharge@lfpBattery.batCircuitElement(b, 1 * b.rnEl * Q));
        end
        function i = findImaxD(b)
            i = sum(findImaxD@lfpBattery.batCircuitElement(b));
            [b.ImaxD] = deal(i);
        end
        function i = findImaxC(b)
            i = sum(findImaxC@lfpBattery.batCircuitElement(b));
            [b.ImaxC] = deal(i);
        end
    end
    
    methods (Access = 'protected')
        function chargeLoop(b, qv)
            % Loop over each element and charge with a vector of charges
            for i = 1:b.nEl
                b.El(i).charge(qv(i))
            end
        end
        function p = getZProportions(b)
            if isempty(b.ecache{3})
                % lowest impedance --> highest current
                zv = [b.El.Zi]; % vector of internal impedances
                b.ecache{3} = zv' ./ sum(zv);
                b.ecache{3} = (1./b.ecache{3}) ./ sum(1./b.ecache{3});
            end
            p = b.ecache{3};
        end
        function refreshNominals(b)
            b.Vn = sum([b.El.Vn]) * b.rnEl;
            b.Cn = sum([b.El.Cn]);
        end 
        function s = sohCalc(b)
            s =  sum([b.El.SoH]) / double(b.nEl);
        end
    end
    
end

