function plotEigenmodes(handles, selection, h1, h2)
%PLOTEIGENMODE   Plot the eigenmodes in the GUI
% Calling sequence
%   PLOTEIGENMODES(HANDLES, SELECTION, H1, H2)
% where
%   HANDLES:    MATLAB handle object of the CHEBGUI figure.
%   SELECTION:  The user choice of a desired eigenvalue to be plotted, i.e. if 
%               a user selects an eigenvalue from the list shown after the
%               problem is solved.
%   H1:         A handle to the top plot of the CHEBGUI figure.
%   H2:         A handle to the bottom plot of the CHEBGUI figure.

% Copyright 2014 by The University of Oxford and The Chebfun Developers. 
% See http://www.chebfun.org/chebfun/ for Chebfun information.

% No recent solution available
if ( ~handles.hasSolution )
    return
else
    % Obtain the most recent eigenvalues and eigenvectors
    D = handles.latest.solution;
    V = handles.latest.solutionT;
end

% selection == 0 corresponds to no selection being made, i.e. plot everything
if ( nargin < 2 )
    selection = 0;
end

% Default figures to be plotted at.
if ( nargin < 3 )
    h1 = handles.fig_sol;
end
if ( nargin < 4 )
    h2 = handles.fig_norm;
end

% Always create the same number of colours to preserve colours if selection
% is changed.
C = get(0, 'DefaultAxesColorOrder');
C = repmat(C, ceil(length(D)/size(C, 1)), 1);

% Number of unknown variables in the problem
numVar = size(V, 1);

% Need to trim the data we are plotting if user has made a selection
if ( selection )
    % Pick out the selected eigenvalues
    D = D(selection);
    
    % Go through the rows of the CHEBMATRIX V and pick out the selected entries
    chebfunSelection = cell(numVar, 1);
    
    % Loop through the rows of the CHEBMATRIX V
    for selCounter = 1:numVar
        Vtemp = V{selCounter};
        chebfunSelection{selCounter} = Vtemp(:,selection);
    end
    
    % Convert the cell of selected CHEBFUNS to a CHEBMATRIX
    V = chebmatrix(chebfunSelection);

    % Pick out the colour needed for plotting the selected eigenvalues.
    C = C(selection,:);
end

if ( ~isempty(h1) )
    % Ensure that we still have the same x and y-limits on the plots. Only
    % do that when we are not plotting all the information

    if ( selection )
        xlim_sol = xlim(h1);
        ylim_sol = ylim(h1);
    end
    
    axes(h1)
    for k = 1:size(D)
        plot(real(D(k)), imag(D(k)), '.', 'markersize', 25, 'color', C(k,:));
        hold on
    end
    hold off

    % Show grid?
    if ( handles.guifile.options.grid )
        grid on
    end

    title('Eigenvalues');
    xlabel('real');
    ylabel('imag');

    if ( any(selection) && (nargin < 4) )
        xlim(h1, xlim_sol);
        ylim(h1, ylim_sol);
    end
%     axis equal
    
end

if ( isempty(h2) )
    return
end

% Do we have a coupled system?
isSystem = numVar > 1;

% Number of unknown variables.
nV = max(size(V));

% Do we want to plot the real or the imaginary parts of the eigenvalues?
realplot = get(handles.button_realplot, 'Value');
W = V;
if ( realplot )
    for k = 1:numVar
        V(k) = real(V{k});
    end
    s = 'Real part of eigenmodes';
else
    for k = 1:nV
        V(k) = imag(V{k});
    end
    s = 'Imaginary part of eigenmodes';
end

% TODO: This used to be a chebfunpref('plot_numpts'), do we still want to allow
% that?
maxPlotPoints = 2001;

axes(h2)
% set(h2,'NextPlot','add')
set(h2, 'ColorOrder', C)
if ( any(selection) && (nargin < 4) )
    xlim_norm = xlim(h2);
    ylim_norm = ylim(h2);
end

% Do the plotting for the bottom figure. Coupled systems are more tricky than
% scalar problems.
if ( ~isSystem )
    % Deal with different kinds of plotting required depending on whether we
    % have real+imaginary parts or not.
    if ( (length(selection) == 1) && (selection > 0) && ~isreal(W{1}) && ~isreal(1i*W{1}) )
        d = V.domain;
        xx = union(linspace(d(1), d(end), maxPlotPoints), d).';
        WW = abs(feval(W{1}, xx));
        
        plot(V{1}, '-', 'LineWidth', 2, 'color', C(1,:)); hold on
        plot(xx, WW, '-', xx, -WW, '-', 'LineWidth', 1, 'color', 'k'); hold off
    else
        % Convert to a CHEBFUN
        V = chebfun(V);
        for k = 1:size(V,2)
            plot(V(:,k), 'LineWidth', 2, 'color', C(k,:));
            hold on
        end
        hold off
    end

    % Show grid?
    if ( handles.guifile.options.grid )
        grid on
    end
    % ylabel:
    ylabel(handles.varnames);
    
else
    % Linestyles for the eigenmodes.
    LS = repmat({'-', '--', ':', '-.'}, 1, ceil(numVar/4));
    % Label for the y-axis.
    ylab = [];
    % Deal with different kinds of plotting required depending on whether we
    % have real+imaginary parts or not.
    
    % TODO: Do we want to plot envelopes for systems? It lokos messy..
%     if ( (length(selection) == 1) && (selection > 0) && ~isreal(W{1}) && ~isreal(1i*W{1}) )
%         V1 = V{1};
%         d = domain(V1);
%         xx = union(linspace(d(1), d(end), maxPlotPoints), d).';
%         for selCounter = 1:nV
%             WW = abs(feval(W{selCounter}, xx));
%             plot(real(V{selCounter}), '-', 'LineWidth', 2, 'lineStyle', ...
%                 LS{selCounter}, 'Color', C(1,:));
%             hold on
%             plot(xx, WW, 'k', xx, -WW, 'k', 'lineStyle', LS{selCounter});
%         end
%     else
        for selCounter = 1:numVar
            % If we are plotting selected e-funs, we need to pick out the colors
            if ( any(selection) )
                for sCounter = 1:length(selection)
                    plot(real(V{selCounter}(:,sCounter)), 'linewidth', 2, ...
                        'linestyle', LS{selCounter}, 'Color', C(sCounter,:));
                    hold on
                end
                xLims = V{selCounter}(:,sCounter).domain;
            else
                plot(real(V{selCounter}), 'linewidth', 2, 'linestyle',  ...
                    LS{selCounter});
                hold on
            end
            ylab = [ylab handles.varnames{selCounter} ', ' ]; %#ok<AGROW>
        end
%     end
    hold off
    
    % ylabel:
    ylabel(ylab(1:end-2));
    
end

% Set limits:
if ( any(selection) && (nargin < 4) )
    xlim(xlim_norm);
else
    Vdom = V.domain;
    xlim([Vdom(1) Vdom(end)]);
end
set(h2, 'NextPlot', 'replace')

% Set the xlim according to the domain of the function
xlabel(handles.indVarName);
title(s);

end
