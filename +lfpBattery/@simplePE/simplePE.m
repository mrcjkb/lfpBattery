classdef simplePE < lfpBattery.batCircuitElement
    %SIMPLEPE Simplified implementation of the parallelElement. This
    %version assumes That all battery cells are exactly the same for
    %the purpose of shorter simulation times. This class can be used as a
    %decorator for the simpleSE, other simplePE and batteryCell objects.
    
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
        function b = simplePE(obj, n)
            if ~obj.hasCells
                error('Object being wrapped does not contain any cells.')
            end
            b.El = obj;
            b.nEl = double(n);
            b.findImax;
            b.refreshNominals;
            b.hasCells = true;
        end
        function v = getNewVoltage(b, I, dt)
            % split I equally across elements
            v = b.El.getNewVoltage(I./b.nEl, dt);
        end
        function set.V(b, v)
            % Pass v down
            b.El.V = v;
        end
        function v = get.V(b)
            v = b.El.V; % Voltage is the same across all elements
        end
        function c = get.Cd(b)
            c = b.nEl .* b.El.Cd;
        end
        function c = get.C(b)
            c = b.nEl .* b.El.C;
        end
        function z = get.Zi(b)
            z = 1 ./ (b.nEl ./ b.El.Zi); % 1/z_total = sum_i(1/z_i)
        end
        function addElements(varargin)
            error('addElements is not supported for simplePE objects. The element is passed in the constructor.')
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = b.nEl .* b.El.Imax;
            b.Imax = i;
        end
        function charge(b, Q)
            % Pass equal amount of discharge capacity to each element
            % to account for self-balancing nature of parallel config
            b.El.charge(1 ./ b.nEl .* Q);
        end
        function p = getZProportions(b)
            p = ones(b.nEl, 1) ./ b.nEl;
        end
        function refreshNominals(b)
            b.Vn = b.El.Vn;
            b.Cn = b.nEl .* b.El.Cn;
        end 
        function s = sohCalc(b)
            s = b.El.SoH;
        end
        function c = dummyCharge(b, Q)
            c = b.nEl .* b.El.dummyCharge(Q ./ b.nEl);
        end
    end
end

