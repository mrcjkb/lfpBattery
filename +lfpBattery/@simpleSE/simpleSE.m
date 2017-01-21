classdef simpleSE < lfpBattery.batCircuitElement
    %SIMPLESE Simplified implementation of the seriesElement (active and 
    %passive equalizations). This version assumes That all battery cells
    %are exactly the same for the purpose of shorter simulation times.
    %This class can be used as a decorator for the simplePE, other simpleSE 
    %and batteryCell objects.
    
    properties (Dependent)
        V;
    end
    properties (Dependent, SetAccess = 'immutable')
        Zi;
    end
    properties (Dependent, SetAccess = 'protected')
        Cd;
        C;
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
            v = b.nEl .* b.El.getNewVoltage(I, dt);
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
        function c = get.Cd(b)
            c = b.El.Cd;
        end
        function c = get.C(b)
            c = b.El.C;
        end
        function addElements(varargin)
            error('addElements is not supported for simpleSE objects. The element is passed in the constructor.')
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = b.El.Imax;
            b.Imax = i;
        end
        function charge(b, Q)
            % Pass equal amount of discharge capacity to each element
            b.El.charge(1 ./ b.nEl .* Q);
        end
        function p = getZProportions(b)
            p = ones(b.nEl, 1) ./ b.nEl;
        end
        function c = dummyCharge(b, Q)
            c = b.El.dummyCharge(Q);
        end
        function s = sohCalc(b)
            s = b.El.SoH;
        end
        function refreshNominals(b)
            b.Vn = b.nEl .* b.El.Vn;
            b.Cn = b.El.Cn;
        end 
    end
end

