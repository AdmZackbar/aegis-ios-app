# Aegis

An iOS application to track personal finances.

## Requirements

Money can be transferred in 2 directions: expenses and revenue.
Expenses track outgoing money, whereas revenue is incoming money.
Not all expenses are money 'leaving the system': a down payment is
technically an 'expense', but that money goes to paying for an asset
that is worth the same value in theory. Retirement contributions are
similar.

### Expense Categories

All expenses will include the following:
- Date: the date of the transaction
- Payee (recipient): who/what the money went to
- Amount: the amount of money transferred
- Category: a way to describe the type of expense
- Category Details: additional information specific to the category

#### Car

- Gas: fuel for a car or tool (e.g. lawnmower)
    - Payee: Gas Station
    - Amount: Total Cost
    - Fuel Amount (gallons)
    - Fuel Cost ($/gal)
    - Fuel Octane
    - Purpose: personal car, tools, other vehicle
- Car Maintenance: car wash, oil change, tire change, etc.
    - Amount: Price
    - Details: type of maintenance plus other info
- Car Insurance
    - Payee: Company
    - Amount: Bill
    - Month the bill is for
- Car Payment: money used to purchase a car
    - Payee: Seller
    - Amount: Amount
    - Details
- Parking: fees for parking some place
    - Payee: Location
    - Amount: Price
    - Details

#### Food

- Groceries: food from a grocery store that is for proper meals
    - Payee: Store
    - Amount: Total Cost
    - Foods: list of foods
        - Food: name, quantity, unit cost, category
- Snacks: food from a store that is just for snacking (i.e. a gas station run)
    - Payee: Store
    - Amount: Total Cost
    - Foods: list of foods
- Restaurants: meal at a place that is typically a bit more expensive than fast food (where a tip is normal)
    - Payee: Restaurant
    - Amount: Bill
    - Tip
    - Details about the circumstances of eating out
- Fast Food: meal at a place where service is quick and a tip is not normal
    - Payee: Restaurant
    - Amount: Cost
    - Details about the circumstances of eating out
- Cookware: gear or utensils used to prepare, serve, or eat food (e.g. pan, silverwear)
    - Payee: Seller
    - Amount: Total Cost
    - Item name(s) and other info
- Grocery Membership: a recurring cost to remain a member at a store (e.g. Costco)
    - Payee: Store
    - Amount: Price
    - Year/Month for the membership

#### Housing

- Rent: regular payment for a rental
    - Payee: Landlord
    - Amount: Amount
    - Month/period of time
- Mortgage Bill: the regular mortgage bill (for interest and principal)
    - Payee: Lender
    - Amount: Amount
    - Month/period of time
- Housing Payment: making a payment on a house (directly for the principal)
    - Payee: Recipient
    - Amount: Amount
    - Details
- Utility Bill: a bill for a service for a house
    - Payee: Company
    - Amount: Total Cost
    - Type: type of utility (e.g. water, electricity, internet)
        - Type (electricity, water): amount of the utility, rate
        - Type (internet, sewer)
    - Month/period of time + other info
- Housing Maintenance: related to upkeep on a house
    - Payee: Seller
    - Amount: Cost
    - Details
- Property Tax: government taxes on a property
    - Amount: Total Amount
    - Year/period of time for
- Appliances: tools used in a house (e.g. fridge, washer)
    - Payee: Seller
    - Amount: Total Cost
    - Name(s) + info
- Furniture: furniture used to furnish a house (e.g. couch, bed)
    - Payee: Seller
    - Amount: Total Cost
    - Name(s) + info
- Decor: decorations for a house (e.g. poster, flag)
    - Payee: Seller
    - Amount: Total Cost
    - Name(s) + info

#### Media

- Video Games: buying/renting a video game or a video game adjacent product
    - Payee: Platform
    - Amount: Price
    - Name of game + other info
- Music: music streaming service subscription or buying music
    - Payee: Platform
    - Amount: Price
    - Details
- TV: movie/TV streaming subscription or buying/renting movies/shows
    - Payee: Platform
    - Amount: Price
    - Details
- Books: buying/renting physical, digital, or audio books
    - Payee: Seller
    - Amount: Price
    - Details
- Games: physical games (e.g. board/card games)
    - Payee: Seller
    - Amount: Price
    - Details
- Other Media: any other type of media (e.g. journalism on SubStack)
    - Payee: Seller
    - Amount: Price
    - Details

#### Medical

- Dental: products related to teeth, visits to dentist (e.g. toothbrush, toothpaste)
    - Payee: Payee
    - Amount: Total Cost
    - Details
- Vision: products related to eyes, visits to eye doctor (e.g. contacts, glasses)
    - Payee: Payee
    - Amount: Total Cost
    - Details
- Medicine: general medicine for health (e.g. ibuprofen, claritin, bandages)
    - Payee: Seller
    - Amount: Price
    - Name(s) + info
- Clinic: visits to a general doctor (e.g. checkup, flu shot)
    - Payee: Clinic
    - Amount: Total Cost
    - Details
- Physical Therapy
    - Payee: Clinic
    - Amount: Total Cost
    - Details
- Hospital: visits to a hospital for some condition or injury (e.g. broken limb, appendicitis)
    - Payee: Hospital
    - Amount: Total Cost
    - Details

#### Personal

- Apparel: clothing, shoes, and other personal items to wear (e.g. shirt, pants, dress shoes, suit)
    - Payee: Seller
    - Amount: Price
    - Name(s) + info
- Hygiene: products for self care (e.g. shampoo, body wash, hair product)
    - Payee: Seller
    - Amount: Price
    - Name(s) + info
- Haircut
    - Payee: Barbershop
    - Amount: Total Cost
    - Tip
    - Barber + info

#### Recreation

- Sports Facility: to access some facility or space for a sport (e.g. gym pass/membership, outdoor day pass)
    - Payee: Payee
    - Amount: Total Cost
    - Sport type (e.g. climbing, running)
    - Details
- Sports Gear: equipment/gear used in a sport (e.g. chalk, climbing/running shoes)
    - Payee: Seller
    - Amount: Price
    - Sport type
    - Name(s) + info
- Sports Event: to *participate* in some sporting event (e.g. climbing comp, race)
    - Payee: Organization
    - Amount: Price
    - Sport type
    - Details
- Recreation Event: to *attend* some recreation event (e.g. concert, bar cover, attending a ball game)
    - Payee: Organization
    - Amount: Price
    - Details

#### Technology

- Tech Devices: self-contained tech-heavy devices (e.g. laptop, phone, watch)
    - Payee: Seller
    - Amount: Price
    - Name + info
- Device Accessories: accessories for a tech device (e.g. phone case, charger)
    - Payee: Seller
    - Amount: Price
    - Name(s) + info
- Computer Parts: components for a PC or other tech device (e.g. GPU, CPU)
    - Payee: Seller
    - Amount: Price
    - Name(s) + info
- Peripherals: accessories for a computer (e.g. monitor, mouse)
    - Payee: Seller
    - Amount: Price
    - Name(s) + info
- Software: any program that runs on a tech device (e.g. Photoshop, app store application)
    - Payee: Seller
    - Amount: Price
    - Name + info
- Tech Service: a service that helps run other devices (e.g. cloud storage, server hosting, phone plan)
    - Payee: Seller
    - Amount: Price
    - Details
- Digital Assets: some digital item that has value (e.g. art assets on Poliigon)
    - Payee: Seller
    - Amount: Price
    - Details

#### Travel

- Accomodations: a temporary place to stay (e.g. AirBnB, hotel)
    - Payee: Company
    - Amount: Total Cost
    - Details
- Rental Car
    - Payee: Company
    - Amount: Total Cost
    - Details
- Airfare
    - Payee: Company
    - Amount: Total Cost
    - Details
- Rideshare: some car transportation service (e.g. taxi, uber)
    - Payee: Company
    - Amount: Total Cost
    - Tip
    - Details

#### Other

- Gift: money/items given to a friend for a personal reason
    - Payee: Recipient
    - Amount: Amount
    - Details
- Charity: money donated to an organization for charity purposes
    - Payee: Organization
    - Amount: Amount
    - Details
- Taxes: federal and state taxes (yearly)
    - Payee: federal, state, other
    - Amount: Total Amount
    - Year/period of time
- Contributions: contributions to 401k, IRA
    - Payee: Bank
    - Amount: Amount
    - Details

### Expense Metadata

Other information such as vacations/trips, dating, are contained in other
tables and link back to the expense table.

#### Examples

Trip: Airfare, Accomodation, Car Rental, etc.
Dates: Restaurants, Gift, etc.
