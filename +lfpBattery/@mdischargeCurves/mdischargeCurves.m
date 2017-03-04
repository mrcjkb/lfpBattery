classdef mdischargeCurves < lfpBattery.dischargeCurves
    %MDISCHARGECURVES sorted collection of dischargeFit (or other curveFitInterface) objects.
    %Overloaded dischargeCurves class that returns the mean of all dischargeFit objects, no matter what the
    %current in it's interp() method.
    %
    %MDISCHARGECURVES  Initializes collection of discharge curves, each with a single current value.
    %MDISCHARGECURVES(d1, d2, .., dn) Initializes collection with
    %                                 curve fits d1, d2, .. up to dn
    %d1, d2, .., dn must implement the curveFitInterface. If two
    %curve fits dn-1 and dn have the same z property, the curve fit
    %dn-1 will be removed.
    %
    %MDISCHARGECURVES Properties:
    %
    %   xydata - Cell array of dischargeFit or other curve fit objects (should implement curveFitInterface)
    %   z      - Vector of currents (in A) at which the respective curve measurements were
    %            recorded
    %
    %MDISCHARGECURVES Methods:
    %
    %   add                 - Adds or converts a curve fit object cf to a collection c.
    %   remove              - Removes the object with the current I.
    %   createIterator      - Returns an iterator for the DISCHARGECURVES object.
    %
    %SEE ALSO: lfpBattery.dischargeFit lfpBattery.curveFitInterface
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         March 2017
    
    methods
        function d = mdischargeCurves(varargin)
            %MDISCHARGECURVES  Initializes collection of discharge curves, each with a single current value.
            %MDISCHARGECURVES(d1, d2, .., dn) Initializes collection with
            %                                 curve fits d1, d2, .. up to dn
            %d1, d2, .., dn must implement the curveFitInterface. If two
            %curve fits dn-1 and dn have the same z property, the curve fit
            %dn-1 will be removed.
            d@lfpBattery.dischargeCurves(varargin{:})
        end
        function v = interp(d, ~, C)
            %INTERP returns the mean voltage in V between calculations of
            %multiple dischargeFits.
            %Syntax: V = d.INTERP(I, C);
            %
            %V = voltage in V
            %I = any integer (Input is ignored in this class)
            %C = capacity in Ah after discharging/charging
            %
            %NOTE: Due to the fact that an extrapolation of low and high
            %currents leads to bad results at a low SoC, the current is
            %limited to the mdischargeCurve's maximum and minimum current
            %recordings (property: z)
            if d.dcache(3) ~= C
                d.dcache(3) = C;
                xx = zeros(d.nEl, 1);
                xydat = d.xydata;
                for i = 1:d.nEl
                    xx(i) = xydat{i}(C);
                end
                d.dcache(1) = mean(xx);
            end
            v = d.dcache(1);
        end
    end
end

