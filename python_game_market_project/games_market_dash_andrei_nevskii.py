import pandas as pd
import dash
import dash_bootstrap_components as dbc
from dash import html
import plotly.express as px
from dash.dependencies import Input, Output
from dash import dcc

df = pd.read_csv('games.csv')

# обработка данных 
df = df[(df['Year_of_Release'] >= 1990) & (df['Year_of_Release'] <= 2010)].dropna()

# преобразование оценок в числовой вид
df['User_Score'] = pd.to_numeric(df['User_Score'], errors='coerce') 
df['Critic_Score'] = pd.to_numeric(df['Critic_Score'], errors='coerce')

# преобразование рейтинга в числовой вид
rating_mapping = {
    'E': 1, 
    'M': 2,  
    'T': 3,  
    'E10+': 4, 
    'AO': 5, 
    'K-A': 6 
}
df['Rating_Num'] = df['Rating'].map(rating_mapping)

app = dash.Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])

# верстка
app.layout = html.Div([
    html.H1("Дашборд игровой индустрии", style={'textAlign': 'left'}),
    html.Div([html.P("Этот дашборд предоставляет визуализацию данных о видеоиграх, выпущенных с 1990 по 2010 год. Вы можете увидеть "
                     "распределения по возрастному рейтингу, оценкам критиков и игроков, а также году выпуска игры.")]),
    html.Hr(),
    
    # Фильтры
    dbc.Row([
        dbc.Col([
            html.H3('Платформы'),
            dcc.Checklist(
                id='platform-filter',
                options=[{'label': platform, 'value': platform} for platform in df['Platform'].unique()],
                value=df['Platform'].unique().tolist(),
                inline=False, 
                style={'columns': 3}
            )
        ], width=4),
        dbc.Col([
            html.H3('Жанры'),
            dcc.Checklist(
                id='genre-filter',
                options=[{'label': genre, 'value': genre} for genre in df['Genre'].unique()],
                value=df['Genre'].unique().tolist(),
                inline=False,
                style={'columns': 3}
            )
        ], width=4),
        dbc.Col([
            html.H3('Интервал годов выпуска'),
            dcc.RangeSlider(
                id='year-filter',
                min=df['Year_of_Release'].min(),
                max=df['Year_of_Release'].max(),
                step=1,
                marks={year: {'label': str(year), 'style': {'transform': 'rotate(-45deg)', 'white-space': 'nowrap'}} for year in range(1990, 2011)},
                value=[df['Year_of_Release'].min(), df['Year_of_Release'].max()]
            )
        ], width=4)

    ]),
    html.Hr(),

    # карточки с числовыми показателями
    html.Div([
        html.Div([
            html.H3("Общее число игр:"),
            html.H4(id='games-count', style={'fontSize': '28px', 'fontWeight': 'bold'})
        ], style={'padding': '20px', 'backgroundColor': '#e0e0e0', 'display': 'inline-block', 'width': '32%'}),

        html.Div([
            html.H3("Общая средняя оценка игроков:"),
            html.H4(id='average-player-score', style={'fontSize': '28px', 'fontWeight': 'bold'})
        ], style={'padding': '20px', 'backgroundColor': '#e0e0e0', 'display': 'inline-block', 'width': '32%'}),

        html.Div([
            html.H3("Общая средняя оценка критиков:"),
            html.H4(id='average-critic-score', style={'fontSize': '28px', 'fontWeight': 'bold'})
        ], style={'padding': '20px', 'backgroundColor': '#e0e0e0', 'display': 'inline-block', 'width': '32%'})
    ], style={'display': 'flex', 'justifyContent': 'space-between'}),
    
    html.Hr(),

    # графики
    html.Div([
        html.Div([html.H3("Средний возрастной рейтинг по жанрам", style={'textAlign': 'center'}), dcc.Graph(id='fig4')], style={'width': '32%', 'display': 'inline-block', 'padding': '10px'}),
        html.Div([html.H3("Оценки игроков и критиков по жанрам", style={'textAlign': 'center'}), dcc.Graph(id='fig5')], style={'width': '32%', 'display': 'inline-block', 'padding': '10px'}),
        html.Div([html.H3("Выпуск игр по годам и платформам", style={'textAlign': 'center'}), dcc.Graph(id='fig6')], style={'width': '32%', 'display': 'inline-block', 'padding': '10px'})
    ], style={'display': 'flex', 'justifyContent': 'space-between'})
], style={
    "padding": "10px",  
    "margin": "0 auto",  
    "max-width": "1600px"  
})  

# связь с фильтрами
@app.callback(
    [Output('games-count', 'children'),
     Output('average-player-score', 'children'),
     Output('average-critic-score', 'children')],
    [Input('platform-filter', 'value'),
     Input('genre-filter', 'value'),
     Input('year-filter', 'value')]
)
def update_metrics(selected_platforms, selected_genres, selected_years):
    # фильтрация данных
    selected_years = selected_years or [df['Year_of_Release'].min(), df['Year_of_Release'].max()]
    
    filtered_df = df[
        (df['Platform'].isin(selected_platforms)) &
        (df['Genre'].isin(selected_genres)) &
        (df['Year_of_Release'].between(selected_years[0], selected_years[1]))
    ]
    
    # метрики
    games_count = len(filtered_df)
    avg_player_score = filtered_df['User_Score'].mean()  
    avg_critic_score = filtered_df['Critic_Score'].mean()  

    return str(games_count), str(avg_player_score), str(avg_critic_score)

# Обновление графиков
@app.callback(
    [Output('fig4', 'figure'),
     Output('fig5', 'figure'),
     Output('fig6', 'figure')],
    [Input('platform-filter', 'value'),
     Input('genre-filter', 'value'),
     Input('year-filter', 'value')]
)
def update_graphs(selected_platforms, selected_genres, selected_years):
    filtered_df = df[
        (df['Platform'].isin(selected_platforms)) &
        (df['Genre'].isin(selected_genres)) &
        (df['Year_of_Release'].between(selected_years[0], selected_years[1]))
    ]
    
    # График 4
    fig4 = px.bar(filtered_df.groupby('Genre').agg({'Rating_Num': 'mean'}).reset_index(), x='Genre', y='Rating_Num')
    
    # График 5
    fig5 = px.scatter(filtered_df, x='Critic_Score', y='User_Score', color='Genre')

    # График 6
    fig6 = px.area(filtered_df.groupby(['Year_of_Release', 'Platform']).size().reset_index(name='Game_Count'), x='Year_of_Release', y='Game_Count', color='Platform')

    return fig4, fig5, fig6

# Запуск приложения
if __name__ == '__main__':
    app.run_server(debug=True)




