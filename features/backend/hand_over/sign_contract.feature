Feature: Sign Contract

  In order to hand things over and sign a contract
  As a lending manager
  I want to be able to hand selected things over and generate a contract

  @javascript
  Scenario: Hand over a selection of items
    Given I am "Pius"
     When I open a hand over
      And I select an item line and assign an inventory code
      And I click hand over
     Then I see a summary of the things I selected for hand over
     When I click hand over inside the dialog
     Then the contract is signed for the selected items

  @javascript
  Scenario: Hand over an not complete quantity of an option line
    Given I am "Pius"
     When I open a hand over
      And I select an option line
      And I set the quantity for that option
      And I click hand over
     Then I see a summary of the things I selected for hand over
      And I see the settet quantity for this option
     When I click hand over inside the dialog
     Then the quantity of options is handed over

  @javascript
  Scenario: Try to hand over unsassigned items
    Given I am "Pius"
     When I open a hand over
      And I select an item without assigning an inventory code
      And I click hand over
     Then I got an error that i have to assign all selected item lines
