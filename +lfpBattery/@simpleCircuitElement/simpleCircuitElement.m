classdef (Abstract) simpleCircuitElement < lfpBattery.batCircuitElement
    %SIMPLECIRCUITELEMENT: Abstract class that holds the common constructor
    %for the simplified circuit elements simplePE and simpleSE.
    %This class's constructor effectively overloads the default
    %batteryInterface constructor, thereby converting the simplePE and
    %simpleSE classes into decorators for the batteryCell class.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    %
    %SEE ALSO: lfpBattery.simplePE lfpBattery.simpleSE
    %lfpBattery.batteryInterface
   
    methods
        function b = simpleCircuitElement(obj)
            b.soh = obj.soh;
            b.socMin = obj.socMin;
            b.socMax = obj.socMax;
            b.soc = obj.soc;
            b.eta_bc = obj.eta_bc;
            b.eta_bd = obj.eta_bd;
        end
    end
end

