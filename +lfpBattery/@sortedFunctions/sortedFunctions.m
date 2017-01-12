classdef (Abstract) sortedFunctions < lfpBattery.composite
    %SORTEDFUNCTIONS Abstract class for storing functions of x and y with
    %different z values.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, January 2017
    
    properties
       z; % Sorted vector holding 3rd dimension of curveFit objects 
    end
    properties (Access = 'protected')
        xydata; % Array of curve fits that implement the curveFitInterface
        errHandler = @lfpBattery.sortedFunctions.minfunErr; % function handle for handling errors in case of operation attempt
    end
    properties (Abstract, Access = 'protected')
        minFuns; % Minimum number of functions permitted
    end
    methods
        function c = sortedFunctions(varargin)
            for i = 1:numel(varargin)
               c.add(varargin{i}); 
            end
        end
        function add(c, d)
            if isempty(c.xydata) % object initialization
               c.xydata = d;
               c.z = d.z;
            else
                try % if another sortedCollection is added, add all the elements of sortedCollection
                    for i = 1:numel(d.xydata)
                        c.add(d.xydata(i))
                    end
                catch
                    c.xydata = [d; c.xydata]; % append new data to beginning
                    [c.z, i, ~] = unique([d.z; c.z]); % append z to beginning and remove double occurences
                    c.xydata = c.xydata(i); % remove double occurences from fits
                    [c.z, i] = sort([c.z]); % sort z data
                    c.xydata = c.xydata(i); % rearrange fits accordingly
                end
            end
            if numel(c.z) >= c.minFuns % set error handler to do nothing
                c.errHandler = @lfpBattery.sortedFunctions.noErr;
            end
        end
        function remove(c, z)
            ind = c.z == z;
            if ~any(ind)
                warning('Nothing found that could be removed.')
            else
                c.z(ind) = [];
                c.xydata(ind) = [];
                if numel(c.z) < c.minFuns % set error handler to return error
                    c.errHandler = @lfpBattery.sortedFunctions.minfunErr;
                end
            end
        end
        function it = createIterator(obj)
            it = lfpBattery.scIterator(obj);
        end
    end
    methods (Static, Access = 'protected')
        function minfunErr(c)
           if c.minFuns == 1
               error('At least 1 object must be added to the collection.')
           else
               error(['At least ', num2str(c.minFuns),' objects must be added to the collection.'])
           end
        end
        function noErr(~)
           % empty function
        end
    end
end