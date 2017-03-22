classdef (Abstract) sortedFunctions < lfpBattery.composite %& lfpBattery.gpuCompatible
    %SORTEDFUNCTIONS Abstract class for storing functions of x and y, each with
    %a single z value.
    %
    %Authors: Marc Jakobi, Festus Anyangbe, Marc Schmidt, January 2017
    
    properties
       z; % Sorted vector holding 3rd dimension of curveFit objects 
    end
    properties (Hidden, Access = 'protected')
        xydata; % Array of curve fits that implement the curveFitInterface
        errHandler = @lfpBattery.sortedFunctions.minfunErr; % function handle for handling errors in case of operation attempt
        nEl; % number of elements in the collection
    end
    properties (Abstract, Access = 'protected')
        minFuns; % Minimum number of functions permitted
    end
    methods
        function c = sortedFunctions(varargin)
            %SORTEDFUNCTIONS  Initializes collection of functions of x and
            %                 y, each with a single z value.
            %SORTEDFUNCTIONS(f1, f2, .., fn) Initializes collection with
            %                                functions f1, f2, .. up to fn
            %f1, f2, .., fn must have a 1x1 z property.
            for i = 1:numel(varargin)
               c.add(varargin{i}); 
            end
        end
        function add(c, d)
            %ADD:   Adds an object to the collection.
            %     Syntax: c.ADD(cf)
            %
            %Can also be used to convert a collection of one class to
            %another class, e.g.
            %d = mdischargeCurves;
            %d.add(dcurves)
            %%-> converts a dischargeCurves object into an mdischargeCurves object.
            %
            %If an object cf with the same z coordinate exists, the
            %existing one is replaced.
            try % This converts one sortedFunctions subclass into another
                if numel(d.xydata) > 1
                    for i = 1:numel(d.xydata)
                        c.add(d.xydata{i})
                    end
                end
            catch
            end
            if isempty(c.xydata) % object initialization
                c.xydata{1} = d;
               c.z = d.z;
            else
                try % if another sortedCollection is added, add all the elements of sortedCollection
                    for i = 1:numel(d.xydata)
                        c.add(d.xydata{i})
                    end
                catch
                    c.xydata = [{d}; c.xydata]; % append new data to beginning
                    [c.z, i, ~] = unique([d.z; c.z]); % append z to beginning and remove double occurences
                    c.xydata = c.xydata(i); % remove double occurences from fits
                    [c.z, i] = sort([c.z]); % sort z data
                    c.xydata = c.xydata(i); % rearrange fits accordingly
                end
            end
            c.nEl = uint32(numel(c.xydata));
            if numel(c.z) >= c.minFuns % set error handler to do nothing
                c.errHandler = @lfpBattery.sortedFunctions.noErr;
            end
        end
        function remove(c, z)
            %REMOVE: Removes the object with the z coordinate specified by z from the collection c.
            %        Syntax: c.REMOVE(z)
            ind = c.z == z;
            if ~any(ind)
                warning('Nothing found that could be removed.')
            else
                c.z(ind) = [];
                c.xydata(ind) = [];
                if numel(c.z) < c.minFuns % set error handler to return error
                    c.errHandler = @lfpBattery.sortedFunctions.minfunErr;
                end
                c.nEl = c.nEl - 1;
            end
        end
        function it = createIterator(c)
            %CREATEITERATOR: Returns an iterator for the object it.
            %                Syntax: it = c.CREATEITERATOR;
            %SEE ALSO: lfpbattery.scIterator
            it = lfpBattery.scIterator(c.xydata);
        end
    end
    
    methods (Access = 'protected')
        % gpuCompatible methods
        % These methods are currently unsupported and may be removed in a
        % future version.
        %{
        function setsubProp(obj, fn, val)
            obj.(fn) = val;
        end
        function val = getsubProp(obj, fn)
            val = obj.(fn);
        end
        %}
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