# Gesells

Money that expires, based on [this story](https://www.noemamag.com/what-if-money-expired/).

> "Gesell believed that the most-rewarded impulse in our present economy is to give as little as possible and to receive as much as possible, in every transaction. In doing so, he thought, we grow materially, morally and socially poorer."

Inspired by ongoing rants like [this](https://x.com/hxrts/status/1752431169465934258?s=20) and [this](https://x.com/hxrts/status/1752329459561050291?s=20), as well as [running experiments](https://honour.community) like [Honour](https://www.kernel.community/en/tokens/token-studies/honour).

## Why Is This Interesting?

As the Noema article explains, there is some legitimate debate about whether expiring money works at scale. It seems to be one of those things which no amount of intellectual argument can solve: we just need to find ways to explore and play around with it in a way which aims to do no harm.

One of the reasons that it may not work at scale is the requirement for some kind of centralized management, captured well in this paragraph:

> "With the use of this stamp scrip currency, the full productive power of the economy would be unleashed. Capital would be accessible to everyone. A Currency Office, meanwhile, would maintain price stability by monitoring the amount of money in circulation. If prices go up, the office would destroy money. When prices fall, it would print more."

We now know of ways to maintain "price stability" which [require](https://www.letsgethai.com/) no [currency](https://reflexer.finance/) [office](https://makerdao.com/). Can we apply some of those lessons to an expiring form of money?

## The Basic Idea

> _Freigeld_ worked like this: A $100 bill of _Freigeld_ would have 52 dated boxes on the back, where the holder must affix a 10-cent stamp every week for the bill to still be worth $100. If you kept the bill for an entire year, you would have to affix 52 stamps to the back of it — at a cost of $5.20 — for the bill to still be worth $100. Thus, the bill would depreciate 5.2% annually at the expense of its holder(s). (The value of and rate at which to apply the stamps could be fine-tuned if necessary.)

Expiration relies on being able to attach some notion of _time_ to each token. Therefore, each token can't be exactly fungible, yet we want transactions to be made easily:

1. We'll use CRED as our numeraire for this experiment (it will be easy to substitute this for AR, U, or some "stable" coin later on if required).
2. You can mint 1 SELL for 1 CRED.
3. Each SELL depreciates at 5.2% annually. 
    1. Arweave blocks occur every ~2 minutes. There are ~262800 blocks per year. So, each block, each SELL should lose 0.00002032%.
4. If you want to redeem your SELL for CRED, the contract will first calculate how much value it has lost.
5. If you want to transfer SELL, the contract will calculate the value lost and only send the remaining amount to the recipient.
6. We implement the "10c coupons on the back of the note" idea by simply advancing the `mintBlock` of your SELL when you buy more.

## Notes

“Today, many of the ways we try to make ourselves and our societies more secure — money, property, possessions, police, the military — have paradoxical effects, undermining the very security we seek and accelerating the harm done to the economy, the climate and people’s lives, including our own.” - Astra Taylor, who might very well be quoting [Alan Watts](https://www.youtube.com/watch?v=OYXLVpyv0f4).