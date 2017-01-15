classdef dischargeCurves < lfpBattery.curvefitCollection
    %DISCHARGECURVES sorted collection of dischargeFit (or other curveFitInterface) objects.
    %Uses interplation to extract data between two curve fits according to
    %the current (stored as the z property).
    %
    %DISCHARGECURVES Properties:
    %
    %   xydata - Array of dischargeFit or other curve fit objects (should implement curveFitInterface)
    %   z      - Array of currents (in A) at which the respective curve measurements were
    %            recorded
    %
    %DISCHARGECURVES Methods:
    %
    %   add                 - Adds a curve fit object cf to a collection c.
    %   remove              - Removes the object with the z coordinate specified by z from the collection c.
    %   createIterator      - Returns an iterator for the DISCHARGECURVES object.
    %
    %SEE ALSO: lfpBattery.dischargeFit lfpBattery.curveFitInterface
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    properties
        interpMethod = 'spline';
    end
    properties (Access = 'protected')
        minFuns = 3; % Minimum number of functions permitted
        Imin; % minimum current
        Imax; % maximum current
    end
    
    methods
        function d = dischargeCurves(varargin)
            %DISCHARGECURVES  Initializes collection of discharge curves, each with a single current value.
            %DISCHARGECURVES(d1, d2, .., dn) Initializes collection with
            %                                curve fits d1, d2, .. up to dn
            %d1, d2, .., dn must implement the curveFitInterface. If two
            %curve fits dn-1 and dn have the same z property, the curve fit
            %dn-1 will be removed.
            d@lfpBattery.curvefitCollection(varargin{:})
        end
        function dischargeFit(d, V, C_dis, I, Temp, varargin)
            %DISCHARGEFIT: Uses Levenberg-Marquardt algorithm to fit a
            %discharge curve of a lithium-ion battery in three parts:
            %1: exponential drop at the beginning of the discharge curve
            %2: according to the nernst-equation
            %3: exponential drop at the end of the discharge curve
            %and adds the fitted curve to the curvefitCollection object c
            %Syntax:
            %   c.dischargeFit(V, C_dis, I, T);
            %           --> initialization of curve fit params with zeros
            %
            %   c.dischargeFit(V, C_dis, I, T, 'OptionName', 'OptionValue');
            %           --> custom initialization of curve fit params
            %
            %Input arguments:
            %   V:              Voltage (V) = f(C_dis) (from data sheet)
            %   C_dis:          Discharge capacity (Ah) (from data sheet)
            %   I:              Current at which curve was measured
            %   T:              Temperature (K) at which curve was mearured
            %
            %OptionName-OptionValue pairs:
            %
            %   'x0'            Initial params for fit functions.
            %                   default: zeros(9, 1)
            %
            %   x0 = [E0; Ea; Eb; Aex; Bex; Cex; x0; v0; delta] with:
            %
            %   E0, Ea, Eb:     Parameters for Nernst fit (initial estimations)
            %   Aex, Bex, Cex:  Parameters for fit of exponential drop at
            %                   the end of the curve (initial estimations)
            %   x0, v0, delta:  Parameters for fit of exponential drop at
            %                   the beginning of the curve (initial estimations)
            %
            %   'mode'          Function used for fitting curves
            %                   'lsq'           - lsqcurvefit
            %                   'fmin'          - fminsearch
            %                   'both'          - (default) a combination (lsq, then fmin)
            
            % add a new dischargeFit object according to the input arguments
            d.add(lfpBattery.dischargeFit(V, C_dis, I, Temp, varargin{:}));
        end % dischargeFit
        function v = interp(d, I, C)
            %INTERP returns interpolated voltage in V between calculations of
            %multiple dischargeCurves.
            %Syntax: V = INTERP(I, C);
            %
            %V = voltage in V
            %I = current in A
            %C = capacity in Ah
            %
            %NOTE: Due to the fact that an extrapolation of low and high
            %currents leads to bad results at a low SoC, the current is
            %limited to the dischargeCurve's maximum and minimum current
            %recordings (property: z)
            I = lfpBattery.commons.upperlowerlim(abs(I), d.Imin, d.Imax);
            % abs(I) is used for discharge curves
            v = d.interp@lfpBattery.curvefitCollection(I, C);
        end
        function add(d, cf)
            %ADD: Adds a curve fit object cf to a dischargeCurve object d.
            %     Syntax: d.ADD(cf)
            %
            %If an object cf with the same current exists, the
            %existing one is replaced.
            d.add@lfpBattery.curvefitCollection(cf);
            d.setCurrentLims
        end
        function remove(d, z)
            d.remove@lfpBattery.curvefitCollection(z);
            d.setCurrentLims
        end
    end
    methods (Access = 'protected')
        function setCurrentLims(d)
            d.Imin = min(d.z);
            d.Imax = max(d.z);
        end
    end
end

