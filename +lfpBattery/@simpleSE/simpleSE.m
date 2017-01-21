classdef (Abstract) simpleSE < lfpBattery.batCircuitElement
    %SIMPLESE Simplified implementation of the seriesElement. This
    %version assumes That all battery cells are exactly the same for
    %the purpose of shorter simulation times. This class's subclasses can be used as a
    %decorator for the simplePE, simpleSEA, simpleSEP and batteryCell classes.
    
    properties (Dependent)
        V;
    end
    properties (Dependent, SetAccess = 'immutable')
        Zi;
    end
    
    methods
        function b = simpleSE(obj, n)
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
            % Voltage = number of elements times elements' voltage
            v = b.nEl .* bEl.getNewVoltage(I, dt);
        end
        function v = get.V(b)
            v = b.nEl .* b.El.V;
        end
        function set.V(b, v)
            % share voltages evenly across elements
            b.El.V = v ./ b.nEl;
        end
        function z = get.Zi(b)
            z = b.nEl .* b.El.Zi;
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = b.El.iMax;
            b.Imax = i;
        end
        function charge(b, Q)
            % Pass equal amount of discharge capacity to each element
            q = 1 ./ b.nEl .* Q;
            charge@lfpBattery.batCircuitElement(b, q)
        end
        function p = getZProportions(b)
            % lowest impedance --> lowest voltage
            zv = [b.El.Zi]; % vector of internal impedances
            p = zv ./ sum(zv);
        end
    end
end

