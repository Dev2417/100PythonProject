import random
rock = '''
    _______
---'   ____)
      (_____)
      (_____)
      (____)
---.__(___)
'''

paper = '''
    _______
---'   ____)____
          ______)
          _______)
         _______)
---.__________)
'''

scissors = '''
    _______
---'   ____)____
          ______)
       __________)
      (____)
---.__(___)
'''
action = [rock, paper, scissors]
user_choice = int(input("What do you choose? Type 0 for Rock,Type 1 for Paper,Type 2 for Scissors?"))
if user_choice >= 0 and user_choice <= 2:
    print(action[user_choice])
computer_choice = random.randint(0,2)
print("Computer chose:")
print(action[computer_choice])
if user_choice >= 3 or user_choice <= 0:
    print("You typed an invalid number. You lose!")
elif computer_choice == 2 and user_choice == 0:
    print("You win!")
elif computer_choice == 0 and user_choice == 2:
    print("You lose!")
elif computer_choice > user_choice:
    print("You lose!")
elif computer_choice > user_choice:
    print("You win!")
elif computer_choice == user_choice:
    print("It's a tie!")
else:
    print("You typed an invalid number. You lose!")