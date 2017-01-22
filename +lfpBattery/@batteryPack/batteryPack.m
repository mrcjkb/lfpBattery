classdef batteryPack < lfpBattery.batteryInterface
    %BATTERYPACK: Cell-resolved model of a lithium ion battery pack.
    %
    
    properties (Dependent)
        V; % Resting voltage of the battery pack in V
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
        % Internal impedance of the battery pack in Ohm.
        % The internal impedance is currently not used as a physical
        % parameter. However, it is used in the circuit elements
        % (seriesElement/parallelElement) to determine the distribution
        % of currents and voltages.
        Zi;
    end
    
    methods
        function b = batteryPack(varargin)
            b@lfpBattery.batteryInterface(varargin{:})
        end % constructor
        function addcurves(b, d)
            b.pass2cells(@addcurves, d);
        end
        function v = getNewVoltage(b, I, dt)
            v = b.El.getNewVoltage(I, dt);
        end
        %% getters & setters
        function set.V(b, v) %#ok<INUSD>
            % Cannot protect SetAcces any other way due to shared interface.
            error('Cannot set read-only property V in batteryPack.')
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
        function charge(b, Q)
            b.El.charge(Q)
        end
        function c = dummyCharge(b, Q)
            c = b.El.dummyCharge(Q);
        end
        function refreshNominals(b)
            b.El.refreshNominals;
        end
        function s = sohCalc(b)
            s = b.El.sohCalc;
        end
        function i = findImax(b)
            i = b.El.findImax;
            b.Imax = i;
        end
    end
end

