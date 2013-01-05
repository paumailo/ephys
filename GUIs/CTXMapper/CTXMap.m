classdef CTXMap < handle
    properties
        CTXImage
        CTXImageInfo
        CTXImageAxes
        CTXFilePath
        TessellData
        Scale
        Points
        PlotType = 'Points';
    end
    
    methods
        
        function h = get.CTXImageAxes(obj)
            if ~ishandle(obj.CTXImageAxes)
                obj.CTXImageAxes = [];
            end
            h = obj.CTXImageAxes;
        end
        
        function obj = loadCTXImage(obj,fpath)
            if ~exist('fpath','var') || isempty(fpath) || ~exist('fpath','file')
                [f,p] = uigetfile({'*.jpg','JPG Image File'},'Locate Image');
                if ~f, return; end
                fpath = fullfile(p,f);
            end
            obj.CTXFilePath  = fpath;
            obj.CTXImageInfo = imfinfo(fpath);
            obj.CTXImage     = imread(fpath);
        end
        
        function addPoints(obj,p)
            if size(p,2) ~= 3
                error('Points property must be Nx3 matrix')
            end
            obj.Points = [obj.Points; p];
        end
        
        function remPoints(obj,ind)
            if ~exist('ind','var') || isempty(ind)
                r = questdlg('This action will remove ALL points. Continue?', ...
                    'Remove All Points','Yes','No','No');
                if strcmp(r,'No'), return; end
                ind = true(1,size(obj.Points,2));
            end
            obj.Points(ind,:) = [];
            obj.updatePlots;
        end
        
        function dispCTXImage(obj)
            if isempty(obj.CTXImage), error('No CTXImage specified'); end
            if isempty(obj.CTXImageAxes), error('CTXImageAxes not available'); end
            ax = obj.CTXImageAxes;
            cla(ax);
            c = obj.CTXImage;
            if ~isempty(c)
                s = size(c);
                c = reshape(c,s(1),s(2)*s(3));
                c = flipud(c);
                c = reshape(c,s);
                image(c,'Parent',ax, ...
                    'ButtonDownFcn',{'CTXMap.CTXclick',obj}, ...
                    'Tag','CTXImage');
                set(ax,'ydir','normal');
                grid(ax,'on');
                
            end
        end
        
        function plotPoints(obj)
            ax = obj.CTXImageAxes;
            if ~exist('ax','var') || isempty(ax), ax = gca; end
            
            delete(findobj('tag','CTXPoints'));
            
            x = obj.Points(:,1);
            y = obj.Points(:,2);
            z = obj.Points(:,3);
            
            [~,cvec] = hist(z(z>0),10);
            cm = jet(10);
            
            hold(ax,'on');
            for i = 1:length(x)
                if z(i) == 0 % no response
                    h(i) = plot(ax,x(i),y(i),'ok', ...
                        'MarkerSize',4,'MarkerFaceColor','k', ...
                        'ButtonDownFcn',{'CTXMap.CTXclick',obj,i});
                elseif z(i) == -1 % NB response only
                    h(i) = plot(ax,x(i),y(i),'ok', ...
                        'MarkerSize',4,'MarkerFaceColor','none', ...
                        'ButtonDownFcn',{'CTXMap.CTXclick',obj,i});
                else % tone response
                    cind = nearest(cvec,z(i));
                    h(i) = plot(ax,x(i),y(i),'o', ...
                        'MarkerSize',4,'MarkerFaceColor',cm(cind,:), ...
                        'Color',cm(cind,:), ...
                        'ButtonDownFcn',{'CTXMap.CTXclick',obj,i});
                end
            end
            hold(ax,'off');
            set(h,'tag','CTXPoints');
        end
        
        
        
        function plotVoronoi(obj)
            if isempty(obj.CTXImageAxes), error('CTXImageAxes not available'); end
            ax = obj.CTXImageAxes;
            
            if isempty(obj.Points), return; end
            
            delete(findobj('tag','CTXvoronoi'));
            
            x = obj.Points(:,1);
            y = obj.Points(:,2);
            z = obj.Points(:,3);
                       
            if length(x) < 3, return; end
            
            hold(ax,'on');
            [~,cvec] = hist(z,10);
            cm = jet(10);
            [c,v] = voronoin([x y]);
            for i = 1:length(v)
                nx = c(v{i},:);
                cind = nearest(cvec,z(i));
                patch(nx(:,1),nx(:,2),cm(cind,:),'parent',ax,'tag','CTXvoronoi');
            end
            k = convhull(x,y);
            plot(ax,x(k),y(k));
            hold(ax,'off');
            
            %             [C,V] = voronoin([x y]);
            %             hold(ax,'on');
            %             for i = 1:length(V)
            %                 nx = C(V{i},:);
            %                 nx(isinf(nx(:,1)),:) = [];
            %                 if size(nx,1) < 3, continue; end
            %                 tri = convhulln(nx);
            %                 for j = 1:size(tri,1)
            %                 	patch(nx(tri(j,:),1),nx(tri(j,:),2),rand,'parent',ax);
            %                 end
            %             end
            %             hold(ax,'off');
            
            %             TRI = delaunay(x,y);
            %             hold(ax,'on');
            %             t = trisurf(TRI,x,y,zeros(size(x)),'Parent',ax);
            %             hold(ax,'off');
            %             view(ax,2);
            %             set(t,'FaceVertexCData',z,'FaceAlpha',0.6, ...
            %                 'LineStyle','none');
            
            hold(ax,'on');
            plot(ax,x,y,'ok','MarkerSize',2,'MarkerFaceColor','k');
            hold(ax,'off');
            
            set(ax,'xlim',xlim(obj.CTXImageAxes), ...
                'ylim',ylim(obj.CTXImageAxes), ...
                'box','on');
            grid(ax,'on');
        end
        
        function updatePlots(obj)
            %             notify(obj,'updateCTXPlots');
            cla(obj.CTXImageAxes);
            obj.dispCTXImage;
            if ~strcmp(obj.PlotType,'None')
                eval(sprintf('obj.plot%s',obj.PlotType));
            end
        end
        
    end
    
    methods(Static)
        function CTXclick(hObj,~,obj,id)
            ax = get(hObj,'Parent');
            cp = get(ax,'CurrentPoint');
            
            p = ancestor(hObj,'figure');
            
            button = get(p, 'SelectionType');
            if strcmp(button,'normal') % left click
                % add point (No Response (NR) = 0; No Tone Response (NTR) = -1
                v = inputdlg('Enter value (0 for ''NR''; -1 for ''NTR:');
                if isempty(v), return; end
                v = str2num(v{1}); %#ok<ST2NM>
                obj.addPoints([cp(1,1) cp(1,2) v]);
                
                
            elseif strcmp(button,'extend') % shift click
                % remove selected point
                if ~exist('id','var') || isempty(id), return; end
                obj.remPoints(id);
                
            elseif strcmp(button,'alt') % right click
                pt = {'None','Voronoi','Points'};
                [s,ok] = listdlg( ...
                    'ListString',pt, ...
                    'SelectionMode','Single','Name','Plot Type', ...
                    'InitialValue',obj.PlotType, ...
                    'PromptString','Select plot type:');
                if ok, obj.PlotType = pt{s}; end
                
            end
            
            obj.updatePlots;
            
        end
    end
    
    events
        updateCTXPlots
    end
    
end