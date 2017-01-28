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
    % randomizeDC       - Slight randomization of each cell's discharge
    %                     curve fits.
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
    % iTol              - Tolerance for current limitation iteration in A.
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
    
    methods
        function b = parallelElement(varargin)
            b@lfpBattery.batCircuitElement(varargin{:})
        end
        function v = getNewVoltage(b, I, dt)
            % split I across elements according to their internal
            % impedance
            p = b.getZProportions;
            v = mean(arrayfun(@(x, y) getNewVoltage(x, y, dt), b.El, I .* p(:)));
        end
        function set.V(b, v)
            % Pass v on to all elements to account for self-balancing
            % nature of parallel config
            [b.El.V] = deal(v);
        end
        function v = get.V(b)
            v = mean([b.El.V]);
        end
        function c = get.Cd(b)
            c = sum([b.El.Cd]);
        end
        function c = get.C(b)
            c = sum([b.El.C]);
        end
        function z = get.Zi(b)
            z = 1 ./ sum((1 ./ [b.El.Zi])); % 1/z_total = sum_i(1/z_i)
        end
        function [np, ns] = getTopology(b)
            [np, ns] = arrayfun(@(x) getTopology(x), b.El);
            np = max(b.nEl .* np);
            ns = max(ns);
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = sum(findImax@lfpBattery.batCircuitElement(b));
            b.Imax = i;
        end
        function charge(b, Q)
            % Pass equal amount of discharge capacity to each element
            % to account for self-balancing nature of parallel config
            q = 1 ./ double(b.nEl) .* Q;
            charge@lfpBattery.batCircuitElement(b, q)
            % MTODO: Set according to proportions, then get V proportions
            % and charge again according to V proportions
        end
        function p = getZProportions(b)
            % lowest impedance --> highest current
            zv = [b.El.Zi]; % vector of internal impedances
            p = zv ./ sum(zv);
            p = (1./p) ./ sum(1./p);
        end
        function refreshNominals(b)
            b.Vn = mean([b.El.Vn]);
            b.Cn = sum([b.El.Cn]);
        end 
        function s = sohCalc(b)
            s =  mean([b.El.SoH]);
        end
        function c = dummyCharge(b, Q)
            q = 1 ./ double(b.nEl) .* Q;
            c = sum(dummyCharge@lfpBattery.batCircuitElement(b, q));
        end
    end
    
end

