classdef cccvFit < lfpBattery.curveFitInterface
    %CCCVFIT: Class for holding a linear fit of the CV phase of a CCCV
    %(constant current, constant voltage) charging curve: Imax = f(SoC)
    %where SoC is the state of charge and Imax is the maximum current. This
    %class can be used by batteryCell objects to limit the maximum current
    %current during the CV phase of charging.
    %
    %Syntax: c = CCCVFIT(soc, iMax);
    %        c = CCCVFIT(soc, iMax, socMax);
    %
    %Input arguments:
    %   soc     - state of charge [0..1].
    %   iMax    - maximum current at soc.
    %   socMax  - (optional) maximum SoC at the end of the CV
    %             phase (default: 1).
    %
    %   The input arguments soc and iMax can be scalars or vectors
    %   of the same size.
    %   Note that only the first value is used for the fit.
    %   However, it may be advisable to include data for multiple
    %   points of the curve to validate that the correspondece is
    %   in fact linear.
    %
    %Notes:
    %   This class inherits from the curveFitInterface class for the sake
    %   of the common methods. However, attempting to access some of the 
    %   curveFitInterface properties (such as 'mode') may return an error,
    %   since the lsq and fmin methods are not used for this class.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt
    %         February 2017
    %
    %SEE ALSO: lfpBattery.curveFitInterface lfpBattery.batteryCell
    
    properties
        soc0; % state of charge at the beginning of the CV phase.
        iMax0; % Maximum current in A during the CC phase.
    end
    properties (Hidden, GetAccess = 'protected', SetAccess = 'immutable')
        socMax = 1; % maximum state of charge at the end of the CV phase.
    end
    properties (Dependent)
       x; % parameters for fit function (not used by this subclass)
    end
    
    methods
        function c = cccvFit(soc, iMax, socMax)
            %CCCVFIT: Creates a linear curve fit of the CV phase of a CCCV
            %(constant current, constant voltage) charging curve: Imax = f(SoC)
            %where SoC is the state of charge and Imax is the maximum
            %current.
            %
            %Syntax: c = CCCVFIT(soc, iMax);
            %        c = CCCVFIT(soc, iMax, socMax);
            %
            %Input arguments:
            %   soc     - state of charge [0..1].
            %   iMax    - maximum current in A at soc.
            %   socMax  - (optional) maximum SoC at the end of the CV
            %             phase (default: 1).
            %
            %   The input arguments soc and iMax can be scalars or vectors
            %   of the same size.
            %   Note that only the first value is used for the fit.
            %   However, it may be advisable to include data for multiple
            %   points of the curve to validate that the correspondece is
            %   in fact linear.
            param = iMax(1) / (1 - soc(1));
            f = @(x, xdata) param * (1 - x);
            c@lfpBattery.curveFitInterface(f, soc, iMax, [])
            if nargin > 2
                c.socMax = socMax;
            end
            c.yylim = [0, inf];
            c.xxlim = [0, 1];
            c.iMax0 = iMax(1);
            c.soc0 = soc(1);
            c.px = param;
        end
        function plotResults(c, newfig, varargin)
            %PLOTRESULTS: Compares a scatter of the raw data with the fit
            %into the current figure window.
            %PLOTRESULTS(true) plots figure into a new figure window
            %PLOTRESULTS(newfig, 'OptionName', 'OptionValue') plots results
            %with additional options. Setting newfig to true plots results
            %in a new figure.
            %
            %Options:
            %   noRawData (logical) - don't scatter raw data (default: false)
            %   noFitData (logical) - don't scatter fit data (default: false)
            if nargin < 2
                newfig = false;
            end
            % Limit input options of plotResults
            p = inputParser;
            addOptional(p, 'noRawData', false, @islogical)
            addOptional(p, 'noFitData', false, @islogical)
            parse(p, varargin{:})
            c.plotResults@lfpBattery.curveFitInterface('newfig', newfig, varargin{:})
            if ~p.Results.noFitData
                hold on
                soc = linspace(c.soc0, c.socMax, 1000)';
                plot(soc, c.func(soc), 'Color', lfpBattery.const.green, ...
                    'LineWidth', 2)
            end
            xlabel('SoC')
            ylabel('Maximum current / A')
        end
        function set.x(c, ~)
            c.propNonSettable('x')
        end
        function x = get.x(c)
            x = c.px;
        end
    end
    
    methods (Access = 'protected')
        function imax = func(c, soc)
            imax = c.px * (1 - soc);
        end
        function fit(c) %#ok<MANU>
            % overload fit function to do nothing
        end
    end
    
    methods (Static, Access = 'protected')
        function setModeErrorHandler
            c.propNonSettable('mode')
        end
        function propNonSettable(propName)
            error(['The property ''', propName, ''' is not settable for cccvFit objects.'])
        end
    end
end


