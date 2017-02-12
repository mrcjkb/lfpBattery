classdef (Abstract) seriesElement < lfpBattery.batCircuitElement
    %SERIESELEMENT: Abstract Composite/decorator (wrapper) for batteryCells and other
    %composite decorators that implement the batCircuitElement interface.
    %Used to create a string circuitry of cells or parallel elements or a
    %combination.
    %
    %SEE ALSO: lfpBattery.batteryPack lfpBattery.batteryCell
    %          lfpBattery.batCircuitElement lfpBattery.seriesElementPE
    %          lfpBattery.seriesElementAE lfpBattery.parallelElement
    %          lfpBattery.simpleSE lfpBattery.simplePE
    %
    %Authors: Marc Jakobi, Festus Anynagbe, Marc Schmidt
    %         January 2017
    properties (Dependent, SetAccess = 'protected')
        % Internal impedance in Ohm.
        % The internal impedance is currently not used as a physical
        % parameter. However, it is used in the circuit elements
        % (seriesElement/parallelElement) to determine the distribution
        % of currents and voltages.
        Zi;
    end
    properties (Hidden, Access = 'protected')
        ecache = cell(2, 1);
    end
    
    methods
        function b = seriesElement(varargin)
            b@lfpBattery.batCircuitElement(varargin{:})
        end
        function v = getNewVoltage(b, I, dt)
            v = 0;
            for i = 1:b.nEl
                v = v + b.El(i).getNewVoltage(I, dt);
            end
        end
        function z = get.Zi(b)
            if isempty(b.ecache{1})
                b.ecache{1} = sum([b.El.Zi]);
            end
            z = b.ecache{1};
        end
        function [np, ns] = getTopology(b)
            [np, ns] = arrayfun(@(x) getTopology(x), b.El);
            ns = max(b.nEl * ns);
            np = max(np);
        end
        function i = findImaxD(b)
            i = min(findImaxD@lfpBattery.batCircuitElement(b));
            [b.ImaxD] = deal(i);
        end
        function i = findImaxC(b)
            i = min(findImaxC@lfpBattery.batCircuitElement(b));
            [b.ImaxC] = deal(i);
        end
    end
    
    methods (Access = 'protected')
        function p = getZProportions(b)
            % lowest impedance --> lowest voltage
            if isempty(b.ecache{2})
                zv = [b.El.Zi]; % vector of internal impedances
                b.ecache{2} = zv' / sum(zv);
            end
            p = b.ecache{2};
        end
    end
    
end

