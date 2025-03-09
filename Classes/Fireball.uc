class Fireball extends GGFireballActor;

var PhysicalMaterial bouncingMaterial;
var GGPawn mHitPawn;

simulated event PostBeginPlay()
{
	local PhysicalMaterial physMat;
	local string oldName;

	super.PostBeginPlay();
	//Make fireball bouncy
	oldName=GetActorName();
	if(oldName == "")
	{
		physMat=bouncingMaterial;
	}
	else
	{
		physMat=new class'PhysicalMaterial' (bouncingMaterial);
		//physMat.PhysicalMaterialProperty=new class'GGPhysicalMaterialProperty' (GGPhysicalMaterialProperty(bouncingMaterial.PhysicalMaterialProperty));
		GGPhysicalMaterialProperty(physMat.PhysicalMaterialProperty).SetActorName(oldName);
	}
	CollisionComponent.SetPhysMaterialOverride(physMat);
	//Set custom explosion (invisible and small)
	mDamageRadius=10.f;
	mExplosiveMomentum=0.f;
	mPhysProp=none;
}

event HitWall( vector HitNormal, actor Wall, PrimitiveComponent WallComp )
{
	//WorldInfo.Game.Broadcast(self, "HitWall " @ Wall);
}

simulated function ProcessTouch( Actor other, vector hitLocation, vector hitNormal )
{
	//WorldInfo.Game.Broadcast(self, "ProcessTouch " @ other);
}

event Landed( vector HitNormal, actor FloorActor )
{
	//WorldInfo.Game.Broadcast(self, "Landed " @ FloorActor);
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
	//WorldInfo.Game.Broadcast(self, "Bump " @ Other);
	mHitPawn = GGPawn(Other);
	if(mHitPawn != none)
	{
		Explode();
	}
}

function Collided( Actor other, optional PrimitiveComponent otherComp, optional vector hitLocation, optional vector hitNormal, optional bool shouldAddMomentum )
{
	//WorldInfo.Game.Broadcast(self, "Collided " @ other);
	mHitPawn = GGPawn(Other);
	if(mHitPawn != none)
	{
		Explode();
	}
}

simulated event TakeDamage( int damage, Controller eventInstigator, vector hitLocation, vector momentum, class< DamageType > damageType, optional TraceHitInfo hitInfo, optional Actor damageCauser )
{
	//WorldInfo.Game.Broadcast(self, "TakeDamage " @ damageCauser);
}


function FindExtraTargets()
{
	local GGPawn gpawn;

	//traceStart=Location + (wrenchMesh.Translation >> Rotation);
	//DrawDebugLine (traceStart, traceStart + (Normal(vector(Rotation)) * wrenchRadius), 0, 0, 0,);

	//WorldInfo.Game.Broadcast(self, "FindExtraTargets() wrenchRadius=" $ wrenchRadius);
	foreach OverlappingActors( class'GGPawn', gpawn, mDamageRadius, Location)
    {
		if(gpawn != none)
	    {
	        mHitPawn = gpawn;
			Explode();
	        break;
	    }
    }
}

simulated event Tick( float delta )
{
	local GGPawn gpawn;
	local float currVelocity;

	if(!mIsExploding)
	{
		// Try to prevent pawns from walking on it
		foreach BasedActors(class'GGPawn', gpawn)
		{
			mHitPawn = gpawn;
			Explode();
		}
	}

	// Destroy the fireball if it's too slow
	currVelocity=VSize(Velocity);
	if(!mIsExploding && currVelocity > 0.f)
	{
		if(currVelocity < 1.f)
		{
			Explode();
		}
	}

	// Find ragdoll bodies
	if(!mIsExploding)
	{
		FindExtraTargets();
	}
}

//Small radius damage that is not actually an explosion (to avoid scaring NPCs)
function Explode()
{
	if( !mIsExploding )
	{
		mIsExploding = true;

		mExplosionLoc = Location;
		// Makes sure the pawn hit is on fire
		if(mHitPawn != none)
		{
			mHitPawn.SetOnFire(true);
			mHitPawn.ClearTimer('SetOnFire');
			mHitPawn.SetTimer( FRand() * 2.0f + 8.0f, false, 'SetOnFire');
		}
		// Apply damages
		HurtRadius( mDamage, mDamageRadius, mDamageType, mExplosiveMomentum, mDealExplosionDamageFromMeshBoundsOrigin ? StaticMeshComponent.Bounds.Origin : Location, , mExplosionCauserController, true );
		// Make sure we're destroyed and cleaned up after we've exploded.
		LifeSpan = 0.1f;
	}

	if( mFirePSComp != none )
	{
		mFirePSComp.DeactivateSystem();
	}
}

DefaultProperties
{
	bBounce = true
	bouncingMaterial=PhysicalMaterial'Heist_PhysMats.Meshes.PhysMat_PoliceDoughnut'
}