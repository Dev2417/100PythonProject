print("Welcome to the Tip Calculator!")
bill = float(input("What was the total bill?\n"))
tip = int(input("How much tip would you like to give 10 12 15?\n"))
people = int(input("How many people are splitting the bill?\n"))
cost = (bill*(tip/100+1))/people
print(f"The total amount tompay for each person is=${round(cost,2)}")
