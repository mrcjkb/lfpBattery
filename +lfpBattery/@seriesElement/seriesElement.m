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
    properties (Dependent, SetAccess = 'immutable')
        % Internal impedance in Ohm.
        % The internal impedance is currently not used as a physical
        % parameter. However, it is used in the circuit elements
        % (seriesElement/parallelElement) to determine the distribution
        % of currents and voltages.
        Zi;
    end
    
    methods
        function b = seriesElement(varargin)
            b@lfpBattery.batCircuitElement(varargin{:})
        end
        function v = getNewVoltage(b, I, dt)
            v = sum(arrayfun(@(x) getNewVoltage(x, I, dt), b.El));
        end
        function z = get.Zi(b)
            z = sum([b.El.Zi]);
        end
        function [np, ns] = getTopology(b)
            [np, ns] = arrayfun(@(x) getTopology(x), b.El);
            ns = max(b.nEl .* ns);
            np = max(np);
        end
    end
    
    methods (Access = 'protected')
        function i = findImax(b)
            i = min(findImax@lfpBattery.batCircuitElement(b));
            b.Imax = i;
        end
        function p = getZProportions(b)
            % lowest impedance --> lowest voltage
            zv = [b.El.Zi]; % vector of internal impedances
            p = zv ./ sum(zv);
        end
    end
    
end

