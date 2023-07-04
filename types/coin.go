package types

import (
	"math/big"

	sdkmath "cosmossdk.io/math"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

const (
	// AttoFury defines the default coin denomination used in Pointguard in:
	//
	// - Staking parameters: denomination used as stake in the dPoS chain
	// - Mint parameters: denomination minted due to fee distribution rewards
	// - Governance parameters: denomination used for spam prevention in proposal deposits
	// - Crisis parameters: constant fee denomination used for spam prevention to check broken invariant
	// - EVM parameters: denomination used for running EVM state transitions in Pointguard.
	AttoFury string = "afury"

	// BaseDenomUnit defines the base denomination unit for Furys.
	// 1 fury = 1x10^{BaseDenomUnit} afury
	BaseDenomUnit = 18

	// DefaultGasPrice is default gas price for evm transactions
	DefaultGasPrice = 20
)

// PowerReduction defines the default power reduction value for staking
var PowerReduction = sdkmath.NewIntFromBigInt(new(big.Int).Exp(big.NewInt(10), big.NewInt(BaseDenomUnit), nil))

// NewFuryCoin is a utility function that returns an "afury" coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewFuryCoin(amount sdkmath.Int) sdk.Coin {
	return sdk.NewCoin(AttoFury, amount)
}

// NewFuryDecCoin is a utility function that returns an "afury" decimal coin with the given sdkmath.Int amount.
// The function will panic if the provided amount is negative.
func NewFuryDecCoin(amount sdkmath.Int) sdk.DecCoin {
	return sdk.NewDecCoin(AttoFury, amount)
}

// NewFuryCoinInt64 is a utility function that returns an "afury" coin with the given int64 amount.
// The function will panic if the provided amount is negative.
func NewFuryCoinInt64(amount int64) sdk.Coin {
	return sdk.NewInt64Coin(AttoFury, amount)
}
