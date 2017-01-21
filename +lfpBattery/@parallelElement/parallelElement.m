classdef parallelElement < lfpBattery.batCircuitElement
    %PARALLELELEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent)
        V;
    end
    properties (Dependent, SetAccess = 'protected')
        Cd;
        C;
    end
    properties (Dependent, SetAccess = 'immutable')
        Zi;
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
%             disp('get')
%             disp([b.El.C])
%             disp(c)
        end
        function z = get.Zi(b)
            z = 1 ./ sum((1 ./ [b.El.Zi])); % 1/z_total = sum_i(1/z_i)
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
%             disp('dummy')
%             disp(dummyCharge@lfpBattery.batCircuitElement(b, q));
%             disp(c)
        end
    end
    
end

