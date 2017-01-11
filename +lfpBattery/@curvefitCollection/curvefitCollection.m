classdef curvefitCollection < lfpBattery.sortedFunctions
    %CURVEFITCOLLECTION sorted collection of curveFit objects. Uses
    %interplation to extract data between two curve fits according to z
    %value
    %
    %curvefitCollection Properties:
    %
    %   xydata - curve fit objects (should implement curveFitInterface)
    %   z      - z data at which the respective curve measurements were
    %            recorded (i. e. temperature, current,...)
    %
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         January 2017
    
    properties (Abstract)
        interpMethod; % Method for interpolation
    end
    
    methods
        function c = curvefitCollection(varargin)
            c@lfpBattery.sortedFunctions(varargin{:})
        end
        
        function y = calc(c, z, x)
            %CALC the y data for a given z and x values.
            %Syntax: y = CALC(z, x)
            %z must have a length of 1
            if numel(z) ~= 1
                error('z must have a length of 1')
            end
            chk = c.z == z;
            if any(chk) % exact match?
                tmp = c.xydata(chk);
                y = tmp(x);
            else % interpolation
                y = c.interp(z, x);
            end
        end
        
        function add(c, d)
           c.validateInputInterface(d);
           c.add@lfpBattery.sortedFunctions(d);
        end
        function plotResults(c, newfig)
            %PLOTRESULTS: Compares scatters of the raw data with the fits
            %in a figure window.
            %PLOTRESULTS(newfig) determines whether a new figure window
            %should be opened or not (default: false)
            if nargin < 2
                newfig = true;
            end
            if newfig
                figure;
            end
            hold on
            tmp = c.xydata(1);
            tmp.plotResults(false);
            legend('raw data', 'fits', 'Location', 'Best')
            grid on
            for i = 2:numel(c.xydata)
                tmp = c.xydata(i);
                tmp.plotResults(false);
            end
        end
    end
    methods (Abstract, Access = 'protected')
        %INTERP returns interpolated result between calculations of
        %multiple curveFits.
        %Syntax: y = INTERP(z, x)
        y = interp(c, z, x);
    end
    methods (Static)
        function validateInputInterface(obj)
            lfpBattery.commons.validateInterface(obj, 'lfpBattery.curveFitInterface');
        end
    end
end

