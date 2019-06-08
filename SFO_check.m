function SFO_check
%----------------------------------------------------------------------------------------------
% Check the SFO algorithm
%----------------------------------------------------------------------------------------------
n_time  = 20;                                                % number of weeks

[ a,p,s_required,y0,c_store,c_cust_0,n_foods,lbl_foods ] = set_parameters();

[ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    deal( zeros(n_time,n_foods) );

c_cust(1:2,:)    = ones(2,1)*c_cust_0;                       % initial cost

[ s_actual_all ] = deal( zeros(n_time,1) );

for i=3:n_time                                               % begin at time step 3
    for j=1:n_foods
        [ y_supply(i,j),s_actual(i,j),y_demand(i,j),y_cust(i,j),y_waste(i,j),...
            s_actual_end(i,j),m_profit(i,j),c_cust(i,j) ] = ...
            calc_foods( a(j), p(:,j), s_required(j), y0(j), c_store(j), ...
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
fig = figure(100); fig.Name = 'time series'; clf
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


function [ a,p,s_required,y0,c_store,c_cust_0,n_foods,lbl_foods ] = set_parameters()
%----------------------------------------------------------------------------------------------
% set the parameters of the foods
%----------------------------------------------------------------------------------------------
lbl_foods = {'food A','food B','food C'};

n_foods   = length(lbl_foods);

[ a,s_required,y0,c_store ] = deal( ones(1,n_foods) );

c_cust_0  = [ 3.1 4 6.9 ];

p = ones(18,n_foods)./[10 8 5];



function [ y_supply,s_actual,y_demand,y_cust,y_waste,s_actual_end,m_profit,c_cust ] = ...
    calc_foods( a, p, s_required, y0, c_store, ...
    y_demand_1, s_actual_end_1, s_actual_all_2, c_cust_1 )
%----------------------------------------------------------------------------------------------
% calculate y, s, m for a specific food
%----------------------------------------------------------------------------------------------
y_supply  = max([
    s_required - s_actual_end_1
    y_demand_1 - s_actual_end_1
    0 ]);
s_actual  = y_supply + s_actual_end_1;
y_demand  = y0 - c_cust_1/a + p(18)*s_actual_all_2;
y_cust    = min( y_demand, s_actual );
y_waste   = max( s_actual/p(16) - y_cust, 0 );
s_actual_end = s_actual - y_cust - y_waste;
c_cust    = c_cust_1;                                        % temporarily use constant cost
m_profit  = c_cust*y_cust - y_supply*c_store - ...
    (p(4) + p(17)*s_actual_all_2)*s_actual - p(2)*y_supply;

