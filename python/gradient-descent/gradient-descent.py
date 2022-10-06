#!/usr/bin/env python3

import csv

def update_w_and_b(spendings, sales, w, b, alpha):
    dl_dw = 0.0
    dl_db = 0.0
    N = len(spendings)

    for i in range(N):
        dl_dw += -2 * spendings[i] * (sales[i] - (w * spendings[i] + b))
        dl_db += -2 * (sales[i] - (w * spendings[i] + b))

    w = w - (1 / float(N)) * dl_dw * alpha
    b = b - (1 / float(N)) * dl_db * alpha

    return w, b

def train(spendings, sales, w, b, alpha, epochs):
    for e in range(epochs):
        w, b = update_w_and_b(spendings, sales, w, b, alpha)

        if e % 400 == 0:
            print("epoch: ", e, "loss: ", avg_loss(spendings, sales, w, b))

    return w, b

def avg_loss(spendings, sales, w, b):
    N = len(spendings)
    total_error = 0.0

    for i in range(N):
        total_error += (sales[i] - (w * spendings[i] + b)) ** 2

    return total_error / float(N)

def predict(x, w, b):
    return w * x + b

def train_with_skl(x, y):
    from sklearn.linear_model import LinearRegression
    model = LinearRegression().fit(x, y)
    return model

def load_spendings_sales():
    spending = []
    sales = []

    sales_idx = None
    with open('Advertising.csv', newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        for row in reader:
            if row[0] == '':
                continue

            spending.append(float(row[2])) # Radio Spending
            sales.append(float(row[4]))

    return spending, sales

spending, sales = load_spendings_sales()
w, b = train(spending, sales, 0.0, 0.0, 0.001, 15000)
x_new = 23.0
y_new = predict(x_new, w, b)
print(y_new)


model = train_with_skl(list(map(lambda x: [x, 1], spending)), sales)
x_new = 230.0
y_new = model.predict([[x_new, 1]])
print(y_new)

