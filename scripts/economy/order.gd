class_name Order
extends RefCounted
## One customer's request. State prevents double completion.

enum State { OPEN, COMPLETED }

var id: int = 0
var customer_id: int = 0
var recipe: Recipe
var state: State = State.OPEN
