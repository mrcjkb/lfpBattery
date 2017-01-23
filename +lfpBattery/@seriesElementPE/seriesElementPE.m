classdef seriesElementPE < lfpBattery.seriesElement
    %SERIESELEMENTPE: Composite/decorator (wrapper) for batteryCells and other
    %composite decorators that implement the batCircuitElement interface.
    %Used to create a string of cells or parallel elements or a
    %combination (with passive equalization).
    %
    % Syntax:   b = SERIESELEMENTPE;
    %           b = SERIESELEMENTPE('OptionName', 'OptionValue');
    %
    % Elements can be added to a SERIESELEMENTPE object using it's
    % addElements() method. For example, adding n batteryCell objects will
    % create a string element of cells. Adding n parallelElement objects
    % will create a string of parallel elements. Adding a SERIESELEMENTPE
    % to a parallelElement will create a circuit of parallel strings with
    % passive equalization.
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
    % SERIESELEMENTPE Methods:
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
    %
    %
    % SERIESELEMENTPE Properties:
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
    %          lfpBattery.seriesElementAE lfpBattery.parallelElement
    %          lfpBattery.simplePE lfpBattery.simpleSE
    %
    %Authors: Marc Jakobi, Festus Anynagbe, Marc Schmidt
    %         January 2017
    
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
    
    methods
        function b = seriesElementPE(varargin)
            b@lfpBattery.seriesElement(varargin{:})
        end
        function v = get.V(b)
            v = sum([b.El.V]);
        end
        function c = get.Cd(b)
            % total capacity = min of elements' capacities
            % --> discharged capacity = min of elements' discharged
            % capacities, since chargeable capacity is limited with passive
            % equalization
            c = b.Cn - b.C;
        end
        function c = get.C(b)
            c = min([b.El.C]);
        end
        function set.V(b, v)
            % set voltages according to proportions of internal impedances
            p = b.getZProportions;
            v = v .* p(:);
            for i = uint32(1):b.nEl
                b.El(i).V = v(i);
            end
        end
    end
    
    methods (Access = 'protected')
        function refreshNominals(b)
            b.Vn = sum([b.El.Vn]);
            b.Cn = min([b.El.Cn]);
        end 
        function s = sohCalc(b)
            s = min([b.El.SoH]); 
        end
        function c = dummyCharge(b, Q)
            c = min(dummyCharge@lfpBattery.seriesElement(b, Q));
        end
    end
end

