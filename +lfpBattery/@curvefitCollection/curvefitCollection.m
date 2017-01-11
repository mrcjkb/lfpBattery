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
    properties
    end
    
    methods
        function c = curvefitCollection(varargin)
            for i = 1:numel(varargin)
                % Make sure added curve fits implement curveFitInterface
                lfpBattery.commons.validateInterface(varargin{i}, 'lfpBattery.curveFitInterface')
            end
            c@lfpBattery.sortedFunctions(varargin{:})
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
    
end

