function SFO_max_profit
%----------------------------------------------------------------------------------------------
% Check the SFO algorithm
%----------------------------------------------------------------------------------------------
n_time  = 20;                                                % number of weeks
flag_three_hypothetical_foods = true;

[ a,p,s_required,y0,c_store,c_cust_0,n_foods,t_ordinance,lbl_foods ] = ...
    set_parameters(flag_three_hypothetical_foods);

[ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,m_profit_actual,c_cust_profit ] = ...
    deal( zeros(n_time,n_foods) );

c_custs_n        = 300;                                      % number of costs for plotting
c_cust_max       = 10;

[ m_profits,y_resupplies ] = deal( zeros(c_custs_n,n_time,n_foods) );
c_custs          = linspace(0,c_cust_max,c_custs_n);
[ c_cust_opt,y_demands   ] = deal( zeros(3,n_time,n_foods) );

[ s_actual_all ] = deal( zeros(n_time,1) );

for i=3:n_time                                               % begin at time step 3
    for j=1:n_foods
        if i>=t_ordinance(j)
            s_required_j = s_required(j);
        else
            s_required_j = 0;
        end
        [ y_supply(i,j),s_actual(i,j),y_demand(i,j),y_demands(:,i,j),y_cust(i,j),y_waste(i,j),...
            s_actual_end(i,j),m_profit(i,j),m_profit_actual(i,j),c_cust_profit(i,j),...
            m_profits(:,i,j),y_resupplies(:,i,j),c_cust_opt(:,i,j) ] = ...
            calc_foods( a(j), p(:,j), s_required_j, y0(j), c_store(j), ...
            y_demand(i-1,j), s_actual_end(i-1,j), s_actual_all(i-2), c_custs );
    end
    s_actual_all(i) = sum(s_actual(i,:));                    % add all of s_actual
end

plot_results( y_supply,s_actual,s_required,y_demand,y_demands,y_cust,y_waste,m_profit_actual,c_cust_profit,...
    lbl_foods,n_foods )

plot_results_3D( c_custs, m_profits,    c_cust_profit, n_time, n_foods, lbl_foods, ...
    200, 'profits', c_cust_opt )

plot_results_3D( c_custs, y_resupplies, c_cust_profit, n_time, n_foods, lbl_foods, ...
    210, 'resupply', c_cust_opt )


function plot_results_3D( c_custs, m_profits, c_cust_profit, n_time, n_foods, lbl_foods, ...
    figno, fig_lbl, c_cust_opt )
%----------------------------------------------------------------------------------------------
% plot profits
%----------------------------------------------------------------------------------------------
n_col = ceil(n_foods/6);                          % number of columns in the figure
n_row = ceil(n_foods/n_col);                      % number of rows

fig = figure(figno); fig.Name = fig_lbl; clf
for j=1:n_foods
    subplot(n_row,n_col,j)
    c_cust_profit_j = c_cust_profit(:,j);
    c_cust_opt_j    = c_cust_opt(:,:,j);
    c_max           = max([c_cust_profit_j ; c_cust_opt_j(:)]);    % maximum c_cust
    c_index         = find(c_custs<c_max*1.25);                    % indeces for plotting
    imagesc(1:n_time,c_custs(c_index),m_profits(c_index,:,j)), hold on
    plot(   1:n_time,c_cust_profit_j,'k-','LineWidth',2)
    plot(   1:n_time,c_cust_opt_j,   'r:','LineWidth',2), hold off
    if n_foods-j<n_col, xlabel('week'), end
    if mod(j,n_col)==1, ylabel('cost'), end
    ax = gca; ax.YDir = 'normal';
    title(lbl_foods{j}), colorbar
end


function plot_results( y_supply,s_actual,s_required,y_demand,y_demands,c_cust_profit,y_waste,m_profit,c_cust, ...
    lbl_foods,n_foods )
%----------------------------------------------------------------------------------------------
% plot all results
%----------------------------------------------------------------------------------------------
fig = figure(110); fig.Name = 'time series'; clf
subplot(4,2,1), plot(y_supply),      title('y supply')
subplot(4,2,2), plot(y_demand),      title('y demand')
subplot(4,2,3), plot(c_cust_profit), title('y cust')
subplot(4,2,4), plot(y_waste),       title('y waste')
subplot(4,2,5), plot(s_actual),      title('s actual')
subplot(4,2,6), plot(m_profit),      title('m profit')
subplot(4,2,7), plot(c_cust),        title('c cust')

fig_plots = fig.Children;                                   % get all axes
num_plots = length(fig_plots);                              % number of axes
for i_plot=1:num_plots
    for j=1:n_foods
        fig_plots(i_plot).Children(j).LineWidth = 2;        % set line width of each plot
    end
end

subplot(4,2,6), xlabel('weeks')
subplot(4,2,7), xlabel('weeks')
subplot(4,2,8), ax = gca; ax.XTick = []; ax.YTick = []; ax.Visible = 'off';
subplot(4,2,1), legend(lbl_foods,'NumColumns',2,'Position',ax.Position)

subplot(4,2,5), hold on, ax = gca; plot(ax.XLim,s_required*[1 1],'k--'), hold off
subplot(4,2,2), hold on, for l=1:3, plot(squeeze(y_demands(l,:,:)),'k:'), end, hold off


function [ y_supply,s_actual,y_demand,y_demands,y_cust,y_waste,s_actual_end,m_profit,m_profit_actual,c_cust_profit, ...
    m_profits,y_resupplies,c_cust_opt ] = ...
    calc_foods( a, p, s_required, y0, c_store, ...
    y_demand_1, s_actual_end_1, s_actual_all_2, c_custs )
%----------------------------------------------------------------------------------------------
% calculate y, s, m for a specific food
%----------------------------------------------------------------------------------------------
flag_optimizer = false;

y_supply  = max([
    s_required - s_actual_end_1                              % satisfy s_required
    y_demand_1 - s_actual_end_1                              % satisfy previous week demand
    0 ]);                                                    % must be positive
s_actual   = y_supply + s_actual_end_1;                      % s at beginning of week

[ m_profits_neg,~,y_resupplies ] = ...
    profit_neg( c_custs, s_required, y0, a, p, s_actual_all_2, s_actual, c_store );
m_profits = -m_profits_neg;

if flag_optimizer
    c_cust_profit = fminbnd( @(c1) ...
        profit_neg( c1, s_required, y0, a, p, s_actual_all_2, s_actual, c_store ), ...
        0, c_custs(end) );
else
    [ ~,m_profits_index ] = max(m_profits);
    c_cust_profit = c_custs(m_profits_index);
end

[ m_profit_neg,m_profit_actual,y_resupply,c_cust_opt,y_demand,y_demands,y_cust,y_waste,s_actual_end ] = ...
    profit_neg( c_cust_profit, s_required, y0, a, p, s_actual_all_2, s_actual, c_store );
m_profit = -m_profit_neg;

return
%----------------------------------------------------------------------------------------------
% Diagnostic plots
%----------------------------------------------------------------------------------------------
fig = figure(99); fig.Name = 'diagnostics'; clf
subplot(2,1,1), plot(c_custs,m_profits,'b-',c_cust_profit,m_profit,'ro'), hold on
subplot(2,1,2), plot(c_custs,y_resupplies,'b-',c_cust_profit,y_resupplies(m_profits_index),'ro'), hold on
%----------------------------------------------------------------------------------------------
% End of diagnostic plots
%----------------------------------------------------------------------------------------------


function [ m_profit_neg,m_profit_actual,y_resupply,c_cust_opt,y_demand,y_demands,y_cust_actual,...
    y_waste,s_actual_end ] = ...
    profit_neg( c_cust_1, s_required, y0, a, p, s_actual_all_2, s_actual, c_store )
%----------------------------------------------------------------------------------------------
% Negative profit
%----------------------------------------------------------------------------------------------
% Initialize parameters
%----------------------------------------------------------------------------------------------
y0_all      = y0   + p(18)*s_actual_all_2;                   % extra demand due to other foods
c_storage   = p(4) + p(17)*s_actual_all_2;                   % extra cost due to all foods
c_store_all = c_store + p(2);                                % purchase cost + delivery

%----------------------------------------------------------------------------------------------
% Analytical solutions to the optimal demand
%----------------------------------------------------------------------------------------------
y_demands(1) = y0_all/2 - (c_store_all + c_storage)/(2*a);   % y_demand > s_actual
y_demands(2) = y0_all/2 - (c_store_all            )/(2*a);   % intermediate
y_demands(3) = y0_all/2;                                     % y_demand < s_actual/n_life

c_cust_opt   = -(y_demands - y0_all)*a;                      % analytical optima

%----------------------------------------------------------------------------------------------
% Numerical analysis of demand using:
%   Unconstrained purchasing (assume store doesn't run out) for long-term profit maximization
%   Constrained purchasing (used to compute actual profit)
%----------------------------------------------------------------------------------------------
y_demand       = y0_all - c_cust_1/a;                        % price->decrease, s_all->increase
y_cust_actual  = min( y_demand, s_actual );                  % amount purchased (constrained)
y_cust         = y_demand;                                   % amount purchased (to maximize profit)
s_exp          = s_actual/p(16);                             % amount that expires
y_waste        = max( s_exp-y_cust_actual, 0 );              % amount that is discarded
s_actual_end   = s_actual - (y_cust_actual + y_waste);       % amount at end of week
s_actual_begin = max(s_required,y_cust);                     % amount at beginning of week
y_resupply     = y_cust + max( s_exp-y_cust, 0 );            % amount needed (to maximize profit)
y_resupply_actual = s_actual_begin - s_actual_end;           % amount needed (actual)
m_profit       = ...
      y_cust       .*c_cust_1 ...                            % revenue
    - y_resupply    *c_store_all ...                         % cost of replenishing y
    - s_actual_begin*c_storage;                              % cost of storage
m_profit_neg = -m_profit;
m_profit_actual= ...
      y_cust_actual   .*c_cust_1 ...                         % actual revenue
    - y_resupply_actual*c_store_all ...                      % actual cost of replenishing y
    - s_actual_begin   *c_storage;                           % cost of storage    

%----------------------------------------------------------------------------------------------
% Sample calculation for the analytical solution:
%----------------------------------------------------------------------------------------------
%   y     = y_demand = (y0 - c/a)
%   m     = y*(c - c_store - c_storage) = (y0 - c/a)*(c - c_store - c_storage)
%   dm/dc = y0     + (c_store + c_storage)/a - 2c/a = 0
%   2c/a  = y0     + (c_store + c_storage)/a
%   c     = y0*a/2 + (c_store + c_storage)/2
%   y     = y0/2   - (c_store + c_storage)/(2a)
%----------------------------------------------------------------------------------------------
