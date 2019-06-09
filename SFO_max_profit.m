function SFO_max_profit
%----------------------------------------------------------------------------------------------
% Check the SFO algorithm
%----------------------------------------------------------------------------------------------
n_time  = 20;                                                % number of weeks

[ a,p,s_required,y0,c_store,c_cust_0,n_foods,t_ordinance,lbl_foods ] = set_parameters();

[ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    deal( zeros(n_time,n_foods) );

c_cust(1:2,:)    = ones(2,1)*c_cust_0;                       % initial cost

[ s_actual_all ] = deal( zeros(n_time,1) );

for i=3:n_time                                               % begin at time step 3
    for j=1:n_foods
        if i>=t_ordinance(j)
            s_required_j = s_required(j);
        else
            s_required_j = 0;
        end
        [ y_supply(i,j),s_actual(i,j),y_demand(i,j),y_cust(i,j),y_waste(i,j),...
            s_actual_end(i,j),m_profit(i,j),c_cust(i,j) ] = ...
            calc_foods( a(j), p(:,j), s_required_j, y0(j), c_store(j), ...
            y_demand(i-1,j), s_actual_end(i-1,j), s_actual_all(i-2), c_cust(i-1,j) );
    end
    s_actual_all(i) = sum(s_actual(i,:));                    % add all of s_actual
end

plot_results( y_supply,s_actual,y_demand,y_cust,y_waste,m_profit,c_cust,lbl_foods,n_foods )


function plot_results( y_supply,s_actual,y_demand,y_cust,y_waste,m_profit,c_cust, ...
    lbl_foods,n_foods )
%----------------------------------------------------------------------------------------------
% plot all results
%----------------------------------------------------------------------------------------------
fig = figure(110); fig.Name = 'time series'; clf
subplot(4,2,1), plot(y_supply), title('y supply')
subplot(4,2,2), plot(y_demand), title('y demand')
subplot(4,2,3), plot(y_cust),   title('y cust')
subplot(4,2,4), plot(y_waste),  title('y waste')
subplot(4,2,5), plot(s_actual), title('s actual')
subplot(4,2,6), plot(m_profit), title('m profit')
subplot(4,2,7), plot(c_cust),   title('c cust')

fig_plots = fig.Children;                                   % get all axes
num_plots = length(fig_plots);                              % number of axes
for i_plot=1:num_plots
    for j=1:n_foods
        fig_plots(i_plot).Children(j).LineWidth = 2;        % set line width of each plot
    end
end

subplot(4,2,1), legend(lbl_foods)                           % set legend for one plot
subplot(4,2,6), xlabel('weeks')
subplot(4,2,7), xlabel('weeks')


function [ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    calc_foods( a, p, s_required, y0, c_store, ...
    y_demand_1, s_actual_end_1, s_actual_all_2, c_cust_1 )
%----------------------------------------------------------------------------------------------
% calculate y, s, m for a specific food
%----------------------------------------------------------------------------------------------
y_supply  = max([
    s_required - s_actual_end_1                              % satisfy s_required
    y_demand_1 - s_actual_end_1                              % satisfy previous week demand
    0 ]);                                                    % must be positive
s_actual   = y_supply + s_actual_end_1;                      % s at beginning of week
c_cust_opt = fminbnd( @(c1) ...
    profit_neg( y_supply, y0, c1, a, p, s_actual_all_2, s_actual, c_store ), 0, 1000 );

[ m_profit_neg,y_demand,y_cust,y_waste,s_actual_end,c_cust ] = ...
    profit_neg( y_supply, y0, c_cust_opt, a, p, s_actual_all_2, s_actual, c_store );
m_profit = -m_profit_neg;


function [ m_profit_neg,y_demand,y_cust,y_waste,s_actual_end,c_cust ] = ...
    profit_neg( y_supply, y0, c_cust_1, a, p, s_actual_all_2, s_actual, c_store )
y_demand  = y0 - c_cust_1/a + p(18)*s_actual_all_2;          % price->decrease, s_all->increase
y_cust    = min( y_demand, s_actual );                       % min of demand and s
s_waste   = s_actual/p(16);                                  % amount that must be discarded
s_actual_after_cust = s_actual - y_cust;                     % s after cust purchase
y_waste   = min( s_waste, s_actual_after_cust );             % amount left over
s_actual_end = s_actual_after_cust - y_waste;
c_cust    = c_cust_1;                                        % temporarily use constant cost
m_profit  = c_cust*y_cust ...                                % revenue
    - y_supply*c_store ...                                   % cost of y
    -(p(4) + p(17)*s_actual_all_2)*s_actual ...              % cost of storage
    - p(2)*y_supply;                                         % cost of delivery
m_profit_neg = -m_profit;
