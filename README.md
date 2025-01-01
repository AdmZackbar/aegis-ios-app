# Aegis

An iOS application to track personal finances.

## Requirements

Money can be transferred in 2 directions: expenses and revenue.
Expenses track outgoing money, whereas revenue is incoming money.
Not all expenses are money 'leaving the system': a down payment is
technically an 'expense', but that money goes to paying for an asset
that is worth the same value in theory. Retirement contributions are
similar. These transactions should be held in a different format.

### Revenue

Revenue encompasses all transactions where liquid cash is coming in.

- Date
- Payer
- Amount
- Category
    - Paycheck
    - Asset Sale
    - Stock Sale
    - Dividends
    - Gift
    - Tax Return
- Details

### Expenses

All expenses will include the following:
- Date: the date of the transaction
- Payee (recipient): who/what the money went to
- Amount: the amount of money transferred
- Category: a way to describe the type of expense
- Notes: text about the expense
- Additional Details: additional, optional information (e.g. gas pricing, item list)

Other information such as vacations/trips, dating, are contained in other
tables and link back to the expense table.

#### Examples

Trip: Airfare, Accomodations, Car Rentals, etc.
Dates: Restaurants, Gifts, etc.
